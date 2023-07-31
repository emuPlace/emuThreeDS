// Copyright 2023 Citra Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#pragma once

#include "video_core/rasterizer_cache/pixel_format.h"
#include "video_core/renderer_vulkan/vk_common.h"

namespace VideoCore {
struct TextureBlit;
struct BufferTextureCopy;
} // namespace VideoCore

namespace Vulkan {

class Instance;
class DescriptorManager;
class RenderpassCache;
class Scheduler;
class Surface;

class BlitHelper {
public:
    BlitHelper(const Instance& instance, Scheduler& scheduler, DescriptorManager& desc_manager,
               RenderpassCache& renderpass_cache);
    ~BlitHelper();

    bool BlitDepthStencil(Surface& source, Surface& dest, const VideoCore::TextureBlit& blit);

    bool ConvertDS24S8ToRGBA8(Surface& source, Surface& dest, const VideoCore::TextureBlit& blit);

    bool DepthToBuffer(Surface& source, vk::Buffer buffer,
                       const VideoCore::BufferTextureCopy& copy);

private:
    /// Creates compute pipelines used for blit
    vk::Pipeline MakeComputePipeline(vk::ShaderModule shader, vk::PipelineLayout layout);

    /// Creates graphics pipelines used for blit
    vk::Pipeline MakeDepthStencilBlitPipeline();

private:
    const Instance& instance;
    Scheduler& scheduler;
    DescriptorManager& desc_manager;
    RenderpassCache& renderpass_cache;

    vk::Device device;
    vk::RenderPass r32_renderpass;

    vk::DescriptorSetLayout compute_descriptor_layout;
    vk::DescriptorSetLayout compute_buffer_descriptor_layout;
    vk::DescriptorSetLayout two_textures_descriptor_layout;
    vk::DescriptorUpdateTemplate compute_update_template;
    vk::DescriptorUpdateTemplate compute_buffer_update_template;
    vk::DescriptorUpdateTemplate two_textures_update_template;
    vk::PipelineLayout compute_pipeline_layout;
    vk::PipelineLayout compute_buffer_pipeline_layout;
    vk::PipelineLayout two_textures_pipeline_layout;

    vk::ShaderModule full_screen_vert;
    vk::ShaderModule d24s8_to_rgba8_comp;
    vk::ShaderModule depth_to_buffer_comp;
    vk::ShaderModule blit_depth_stencil_frag;

    vk::Pipeline d24s8_to_rgba8_pipeline;
    vk::Pipeline depth_to_buffer_pipeline;
    vk::Pipeline depth_blit_pipeline;
    vk::Sampler linear_sampler;
    vk::Sampler nearest_sampler;
};

} // namespace Vulkan
