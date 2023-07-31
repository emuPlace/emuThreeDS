// Copyright 2023 Citra Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#pragma once

#include <compare>
#include <tsl/robin_map.h>
#include "common/bit_field.h"
#include "common/hash.h"
#include "common/thread_worker.h"
#include "video_core/rasterizer_cache/pixel_format.h"
#include "video_core/renderer_vulkan/vk_common.h"
#include "video_core/renderer_vulkan/vk_shader_gen.h"

namespace Pica {
struct Regs;
}

namespace Common {

struct AsyncHandle {
public:
    AsyncHandle(bool is_done_ = false) : is_done{is_done_} {}

    [[nodiscard]] bool IsDone() noexcept {
        return is_done.load(std::memory_order::relaxed);
    }

    void WaitDone() noexcept {
        std::unique_lock lock{mutex};
        condvar.wait(lock, [this] { return is_done.load(std::memory_order::relaxed); });
    }

    void MarkDone(bool done = true) noexcept {
        std::scoped_lock lock{mutex};
        is_done = done;
        condvar.notify_all();
    }

private:
    std::condition_variable condvar;
    std::mutex mutex;
    std::atomic_bool is_done{false};
};

} // namespace Common

namespace Vulkan {

constexpr u32 MAX_SHADER_STAGES = 3;
constexpr u32 MAX_VERTEX_ATTRIBUTES = 16;
constexpr u32 MAX_VERTEX_BINDINGS = 16;

/**
 * The pipeline state is tightly packed with bitfields to reduce
 * the overhead of hashing as much as possible
 */
union RasterizationState {
    u8 value = 0;
    BitField<0, 2, Pica::PipelineRegs::TriangleTopology> topology;
    BitField<4, 2, Pica::RasterizerRegs::CullMode> cull_mode;
};

union DepthStencilState {
    u32 value = 0;
    BitField<0, 1, u32> depth_test_enable;
    BitField<1, 1, u32> depth_write_enable;
    BitField<2, 1, u32> stencil_test_enable;
    BitField<3, 3, Pica::FramebufferRegs::CompareFunc> depth_compare_op;
    BitField<6, 3, Pica::FramebufferRegs::StencilAction> stencil_fail_op;
    BitField<9, 3, Pica::FramebufferRegs::StencilAction> stencil_pass_op;
    BitField<12, 3, Pica::FramebufferRegs::StencilAction> stencil_depth_fail_op;
    BitField<15, 3, Pica::FramebufferRegs::CompareFunc> stencil_compare_op;
};

struct BlendingState {
    u16 blend_enable;
    u16 color_write_mask;
    Pica::FramebufferRegs::LogicOp logic_op;
    union {
        u32 value = 0;
        BitField<0, 4, Pica::FramebufferRegs::BlendFactor> src_color_blend_factor;
        BitField<4, 4, Pica::FramebufferRegs::BlendFactor> dst_color_blend_factor;
        BitField<8, 3, Pica::FramebufferRegs::BlendEquation> color_blend_eq;
        BitField<11, 4, Pica::FramebufferRegs::BlendFactor> src_alpha_blend_factor;
        BitField<15, 4, Pica::FramebufferRegs::BlendFactor> dst_alpha_blend_factor;
        BitField<19, 3, Pica::FramebufferRegs::BlendEquation> alpha_blend_eq;
    };
};

struct DynamicState {
    u32 blend_color = 0;
    u8 stencil_reference;
    u8 stencil_compare_mask;
    u8 stencil_write_mask;

    auto operator<=>(const DynamicState&) const noexcept = default;
};

union VertexBinding {
    u16 value = 0;
    BitField<0, 4, u16> binding;
    BitField<4, 1, u16> fixed;
    BitField<5, 11, u16> stride;
};

union VertexAttribute {
    u32 value = 0;
    BitField<0, 4, u32> binding;
    BitField<4, 4, u32> location;
    BitField<8, 3, Pica::PipelineRegs::VertexAttributeFormat> type;
    BitField<11, 3, u32> size;
    BitField<14, 11, u32> offset;
};

struct VertexLayout {
    u8 binding_count;
    u8 attribute_count;
    std::array<VertexBinding, MAX_VERTEX_BINDINGS> bindings;
    std::array<VertexAttribute, MAX_VERTEX_ATTRIBUTES> attributes;
};

struct AttachmentInfo {
    VideoCore::PixelFormat color_format;
    VideoCore::PixelFormat depth_format;
};

/**
 * Information about a graphics/compute pipeline
 */
struct PipelineInfo {
    VertexLayout vertex_layout{};
    BlendingState blending{};
    AttachmentInfo attachments{};
    RasterizationState rasterization{};
    DepthStencilState depth_stencil{};
    DynamicState dynamic;

    /// Returns the hash of the info structure
    u64 Hash(const Instance& instance) const;

    [[nodiscard]] bool IsDepthWriteEnabled() const noexcept {
        const bool has_stencil = attachments.depth_format == VideoCore::PixelFormat::D24S8;
        const bool depth_write =
            depth_stencil.depth_test_enable && depth_stencil.depth_write_enable;
        const bool stencil_write =
            has_stencil && depth_stencil.stencil_test_enable && dynamic.stencil_write_mask != 0;

        return depth_write || stencil_write;
    }
};

class Instance;
class Scheduler;
class RenderpassCache;
class DescriptorManager;

/**
 * Stores a collection of rasterizer pipelines used during rendering.
 */
class PipelineCache {
    struct Shader : public Common::AsyncHandle {
        Shader(const Instance& instance);
        Shader(const Instance& instance, vk::ShaderStageFlagBits stage, std::string code);

        ~Shader();

        [[nodiscard]] vk::ShaderModule Handle() const noexcept {
            return module;
        }

        vk::ShaderModule module;
        vk::Device device;
        std::string program;
    };

    class GraphicsPipeline : public Common::AsyncHandle {
    public:
        GraphicsPipeline(const Instance& instance, RenderpassCache& renderpass_cache,
                         const PipelineInfo& info, vk::PipelineCache pipeline_cache,
                         vk::PipelineLayout layout, std::array<Shader*, 3> stages,
                         Common::ThreadWorker* worker);
        ~GraphicsPipeline();

        bool Build(bool fail_on_compile_required = false);

        [[nodiscard]] vk::Pipeline Handle() const noexcept {
            return pipeline;
        }

    private:
        bool ShouldTryCompile();

    private:
        const Instance& instance;
        RenderpassCache& renderpass_cache;
        Common::ThreadWorker* worker;

        vk::Pipeline pipeline;
        vk::PipelineLayout pipeline_layout;
        vk::PipelineCache pipeline_cache;

        PipelineInfo info;
        std::array<Shader*, 3> stages;
    };

public:
    PipelineCache(const Instance& instance, Scheduler& scheduler, RenderpassCache& renderpass_cache,
                  DescriptorManager& desc_manager);
    ~PipelineCache();

    /// Loads the pipeline cache stored to disk
    void LoadDiskCache();

    /// Stores the generated pipeline cache to disk
    void SaveDiskCache();

    /// Binds a pipeline using the provided information
    bool BindPipeline(const PipelineInfo& info, bool wait_built = false);

    /// Binds a PICA decompiled vertex shader
    bool UseProgrammableVertexShader(const Pica::Regs& regs, Pica::Shader::ShaderSetup& setup,
                                     const VertexLayout& layout);

    /// Binds a passthrough vertex shader
    void UseTrivialVertexShader();

    /// Binds a PICA decompiled geometry shader
    bool UseFixedGeometryShader(const Pica::Regs& regs);

    /// Binds a passthrough geometry shader
    void UseTrivialGeometryShader();

    /// Binds a fragment shader generated from PICA state
    void UseFragmentShader(const Pica::Regs& regs);

    /// Binds a texture to the specified binding
    void BindTexture(u32 binding, vk::ImageView image_view, vk::Sampler sampler);

    /// Binds a storage image to the specified binding
    void BindStorageImage(u32 binding, vk::ImageView image_view);

    /// Binds a buffer to the specified binding
    void BindBuffer(u32 binding, vk::Buffer buffer, u32 offset, u32 size);

    /// Binds a buffer to the specified binding
    void BindTexelBuffer(u32 binding, vk::BufferView buffer_view);

    /// Sets the dynamic offset for the uniform buffer at binding
    void SetBufferOffset(u32 binding, u32 offset);

private:
    /// Applies dynamic pipeline state to the current command buffer
    void ApplyDynamic(const PipelineInfo& info, bool is_dirty);

    /// Builds the rasterizer pipeline layout
    void BuildLayout();

    /// Returns true when the disk data can be used by the current driver
    bool IsCacheValid(const u8* data, u64 size) const;

    /// Create shader disk cache directories. Returns true on success.
    bool EnsureDirectories() const;

    /// Returns the pipeline cache storage dir
    std::string GetPipelineCacheDir() const;

private:
    const Instance& instance;
    Scheduler& scheduler;
    RenderpassCache& renderpass_cache;
    DescriptorManager& desc_manager;

    vk::PipelineCache pipeline_cache;
    std::size_t num_worker_threads;
    Common::ThreadWorker shader_workers;
    Common::ThreadWorker pipeline_workers;
    PipelineInfo current_info{};
    GraphicsPipeline* current_pipeline{};
    tsl::robin_map<u64, std::unique_ptr<GraphicsPipeline>, Common::IdentityHash<u64>>
        graphics_pipelines;

    enum ProgramType : u32 {
        VS = 0,
        GS = 2,
        FS = 1,
    };

    std::array<u64, MAX_SHADER_STAGES> shader_hashes;
    std::array<Shader*, MAX_SHADER_STAGES> current_shaders;
    std::unordered_map<PicaVSConfig, Shader*> programmable_vertex_map;
    std::unordered_map<std::string, Shader> programmable_vertex_cache;
    std::unordered_map<PicaFixedGSConfig, Shader> fixed_geometry_shaders;
    std::unordered_map<PicaFSConfig, Shader> fragment_shaders;
    Shader trivial_vertex_shader;
};

} // namespace Vulkan
