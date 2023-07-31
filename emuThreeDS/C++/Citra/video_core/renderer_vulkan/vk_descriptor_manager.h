// Copyright 2023 Citra Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#pragma once

#include <bitset>
#include <compare>
#include "video_core/renderer_vulkan/vk_resource_pool.h"

namespace Vulkan {

constexpr u32 MAX_DESCRIPTORS = 7;
constexpr u32 MAX_DESCRIPTOR_SETS = 3;
constexpr u32 MAX_BATCH_SIZE = 8;

union DescriptorData {
    vk::DescriptorImageInfo image_info;
    vk::DescriptorBufferInfo buffer_info;
    vk::BufferView buffer_view;

    bool operator==(const DescriptorData& other) const noexcept {
        return std::memcmp(this, &other, sizeof(DescriptorData)) == 0;
    }

    bool operator!=(const DescriptorData& other) const noexcept {
        return !operator==(other);
    }
};

using DescriptorSetData = std::array<DescriptorData, MAX_DESCRIPTORS>;

class Instance;
class Scheduler;

class DescriptorManager {
public:
    explicit DescriptorManager(const Instance& instance, Scheduler& scheduler);
    ~DescriptorManager();

    /// Allocates an array of descriptor sets of the provided layout
    std::vector<vk::DescriptorSet> AllocateSets(vk::DescriptorSetLayout layout, u32 num_sets);

    /// Binds a resource to the provided binding
    void SetBinding(u32 set, u32 binding, DescriptorData data);

    /// Builds descriptor sets that reference the currently bound resources
    void BindDescriptorSets();

    /// Sets the dynamic offsets of the buffer at binding
    void SetDynamicOffset(u32 binding, u32 new_offset) {
        dynamic_offsets[binding] = new_offset;
    }

    /// Allocates a descriptor set of the provided layout
    [[nodiscard]] vk::DescriptorSet AllocateSet(vk::DescriptorSetLayout layout) {
        return AllocateSets(layout, 1)[0];
    }

    /// Returns the rasterizer pipeline layout
    [[nodiscard]] vk::PipelineLayout GetPipelineLayout() const noexcept {
        return pipeline_layout;
    }

private:
    /// Builds the rasterizer pipeline layout objects
    void BuildLayouts();

private:
    const Instance& instance;
    Scheduler& scheduler;
    DescriptorPool pool_provider;
    vk::PipelineLayout pipeline_layout;
    vk::DescriptorPool current_pool;
    std::array<u32, 2> dynamic_offsets{};
    std::array<vk::DescriptorSetLayout, MAX_DESCRIPTOR_SETS> descriptor_set_layouts;
    std::array<vk::DescriptorUpdateTemplate, MAX_DESCRIPTOR_SETS> update_templates;
    std::array<DescriptorSetData, MAX_DESCRIPTOR_SETS> update_data{};
    std::array<vk::DescriptorSet, MAX_DESCRIPTOR_SETS> descriptor_sets{};
    std::array<std::vector<vk::DescriptorSet>, MAX_DESCRIPTOR_SETS> set_cache;
    std::bitset<MAX_DESCRIPTOR_SETS> descriptor_set_dirty{};
};

} // namespace Vulkan
