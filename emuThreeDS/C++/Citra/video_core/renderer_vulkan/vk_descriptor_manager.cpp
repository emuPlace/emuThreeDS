// Copyright 2023 Citra Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#include "common/microprofile.h"
#include "video_core/renderer_vulkan/vk_descriptor_manager.h"
#include "video_core/renderer_vulkan/vk_instance.h"
#include "video_core/renderer_vulkan/vk_scheduler.h"

namespace {

MICROPROFILE_DEFINE(Vulkan_DescriptorMgmt, "Vulkan", "Descriptor Set Mgmt", MP_RGB(64, 128, 128));

} // Anonymous namespace

namespace Vulkan {

struct Bindings {
    std::array<vk::DescriptorType, MAX_DESCRIPTORS> bindings;
    u32 binding_count;
};

constexpr static std::array RASTERIZER_SETS = {
    Bindings{
        // Utility set
        .bindings{
            vk::DescriptorType::eUniformBufferDynamic,
            vk::DescriptorType::eUniformBufferDynamic,
            vk::DescriptorType::eUniformTexelBuffer,
            vk::DescriptorType::eUniformTexelBuffer,
            vk::DescriptorType::eUniformTexelBuffer,
        },
        .binding_count = 5,
    },
    Bindings{
        // Texture set
        .bindings{
            vk::DescriptorType::eCombinedImageSampler,
            vk::DescriptorType::eCombinedImageSampler,
            vk::DescriptorType::eCombinedImageSampler,
            vk::DescriptorType::eCombinedImageSampler,
        },
        .binding_count = 4,
    },
    Bindings{
        // Shadow set
        .bindings{
            vk::DescriptorType::eStorageImage,
            vk::DescriptorType::eStorageImage,
            vk::DescriptorType::eStorageImage,
            vk::DescriptorType::eStorageImage,
            vk::DescriptorType::eStorageImage,
            vk::DescriptorType::eStorageImage,
            vk::DescriptorType::eStorageImage,
        },
        .binding_count = 7,
    },
};

constexpr vk::ShaderStageFlags ToVkStageFlags(vk::DescriptorType type) {
    vk::ShaderStageFlags flags;
    switch (type) {
    case vk::DescriptorType::eSampler:
    case vk::DescriptorType::eSampledImage:
    case vk::DescriptorType::eCombinedImageSampler:
    case vk::DescriptorType::eUniformTexelBuffer:
    case vk::DescriptorType::eStorageImage:
        flags = vk::ShaderStageFlagBits::eFragment;
        break;
    case vk::DescriptorType::eUniformBuffer:
    case vk::DescriptorType::eUniformBufferDynamic:
        flags = vk::ShaderStageFlagBits::eFragment | vk::ShaderStageFlagBits::eVertex |
                vk::ShaderStageFlagBits::eGeometry;
        break;
    default:
        LOG_ERROR(Render_Vulkan, "Unknown descriptor type!");
    }

    return flags;
}

DescriptorManager::DescriptorManager(const Instance& instance, Scheduler& scheduler)
    : instance{instance}, scheduler{scheduler}, pool_provider{instance,
                                                              scheduler.GetMasterSemaphore()} {
    BuildLayouts();
    descriptor_set_dirty.set();
    current_pool = pool_provider.Commit();
}

DescriptorManager::~DescriptorManager() {
    const vk::Device device = instance.GetDevice();
    device.destroyPipelineLayout(pipeline_layout);

    for (u32 i = 0; i < MAX_DESCRIPTOR_SETS; i++) {
        device.destroyDescriptorSetLayout(descriptor_set_layouts[i]);
        device.destroyDescriptorUpdateTemplate(update_templates[i]);
    }
}

void DescriptorManager::SetBinding(u32 set, u32 binding, DescriptorData data) {
    DescriptorData& current = update_data[set][binding];
    if (current != data) {
        current = data;
        descriptor_set_dirty[set] = true;
    }
}

void DescriptorManager::BindDescriptorSets() {
    MICROPROFILE_SCOPE(Vulkan_DescriptorMgmt);

    // Update any dirty descriptor sets
    for (u32 i = 0; i < MAX_DESCRIPTOR_SETS; i++) {
        if (descriptor_set_dirty[i]) {
            std::vector<vk::DescriptorSet>& cache = set_cache[i];
            if (cache.empty()) {
                cache = AllocateSets(descriptor_set_layouts[i], MAX_BATCH_SIZE);
            }
            vk::DescriptorSet set = cache.back();
            cache.pop_back();

            instance.GetDevice().updateDescriptorSetWithTemplate(set, update_templates[i],
                                                                 update_data[i][0]);

            descriptor_sets[i] = set;
            descriptor_set_dirty[i] = false;
        }
    }

    scheduler.Record(
        [this, offsets = dynamic_offsets, bound_sets = descriptor_sets](vk::CommandBuffer cmdbuf) {
            cmdbuf.bindDescriptorSets(vk::PipelineBindPoint::eGraphics, pipeline_layout, 0,
                                      bound_sets, offsets);
        });
}

void DescriptorManager::BuildLayouts() {
    std::array<vk::DescriptorSetLayoutBinding, MAX_DESCRIPTORS> set_bindings;
    std::array<vk::DescriptorUpdateTemplateEntry, MAX_DESCRIPTORS> update_entries;

    const vk::Device device = instance.GetDevice();
    for (u32 i = 0; i < MAX_DESCRIPTOR_SETS; i++) {
        const auto& set = RASTERIZER_SETS[i];
        for (u32 j = 0; j < set.binding_count; j++) {
            const vk::DescriptorType type = set.bindings[j];
            set_bindings[j] = vk::DescriptorSetLayoutBinding{
                .binding = j,
                .descriptorType = type,
                .descriptorCount = 1,
                .stageFlags = ToVkStageFlags(type),
            };

            update_entries[j] = vk::DescriptorUpdateTemplateEntry{
                .dstBinding = j,
                .dstArrayElement = 0,
                .descriptorCount = 1,
                .descriptorType = type,
                .offset = j * sizeof(DescriptorData),
                .stride = 0,
            };
        }

        const vk::DescriptorSetLayoutCreateInfo layout_info = {
            .bindingCount = set.binding_count,
            .pBindings = set_bindings.data(),
        };
        descriptor_set_layouts[i] = device.createDescriptorSetLayout(layout_info);

        const vk::DescriptorUpdateTemplateCreateInfo template_info = {
            .descriptorUpdateEntryCount = set.binding_count,
            .pDescriptorUpdateEntries = update_entries.data(),
            .templateType = vk::DescriptorUpdateTemplateType::eDescriptorSet,
            .descriptorSetLayout = descriptor_set_layouts[i],
        };
        update_templates[i] = device.createDescriptorUpdateTemplate(template_info);
    }

    const vk::PipelineLayoutCreateInfo layout_info = {
        .setLayoutCount = MAX_DESCRIPTOR_SETS,
        .pSetLayouts = descriptor_set_layouts.data(),
        .pushConstantRangeCount = 0,
        .pPushConstantRanges = nullptr,
    };
    pipeline_layout = device.createPipelineLayout(layout_info);
}

std::vector<vk::DescriptorSet> DescriptorManager::AllocateSets(vk::DescriptorSetLayout layout,
                                                               u32 num_sets) {
    static std::array<vk::DescriptorSetLayout, MAX_BATCH_SIZE> layouts;
    layouts.fill(layout);

    vk::DescriptorSetAllocateInfo alloc_info = {
        .descriptorPool = current_pool,
        .descriptorSetCount = num_sets,
        .pSetLayouts = layouts.data(),
    };

    try {
        return instance.GetDevice().allocateDescriptorSets(alloc_info);
    } catch (vk::OutOfPoolMemoryError) {
        pool_provider.RefreshTick();
        current_pool = pool_provider.Commit();
        for (auto& cache : set_cache) {
            cache.clear();
        }
        descriptor_set_dirty.set();
    }

    alloc_info.descriptorPool = current_pool;
    return instance.GetDevice().allocateDescriptorSets(alloc_info);
}

} // namespace Vulkan
