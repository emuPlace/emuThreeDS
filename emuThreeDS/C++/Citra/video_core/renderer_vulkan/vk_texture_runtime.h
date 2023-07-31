// Copyright 2023 Citra Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#pragma once

#include <deque>
#include <span>
#include "video_core/rasterizer_cache/framebuffer_base.h"
#include "video_core/rasterizer_cache/rasterizer_cache_base.h"
#include "video_core/rasterizer_cache/surface_base.h"
#include "video_core/renderer_vulkan/vk_blit_helper.h"
#include "video_core/renderer_vulkan/vk_instance.h"
#include "video_core/renderer_vulkan/vk_stream_buffer.h"

VK_DEFINE_HANDLE(VmaAllocation)

namespace VideoCore {
struct Material;
}

namespace Vulkan {

struct Image {
    vk::Image handle;
    VmaAllocation allocation;

    operator vk::Image() const noexcept {
        return handle;
    }
};

struct HostTextureTag {
    vk::Format format;
    VideoCore::TextureType texture_type;
    u32 width;
    u32 height;
    u32 levels;
    u32 res_scale;
    bool is_mutable;
    bool is_custom;
    bool has_normal;

    auto operator<=>(const HostTextureTag&) const noexcept = default;
};

struct Allocation : public HostTextureTag {
    std::array<Image, 3> images;
    std::array<vk::UniqueImageView, 3> image_views;
    vk::ImageAspectFlags aspect{};
    vk::UniqueImageView depth_view{};
    vk::UniqueImageView stencil_view{};
    vk::UniqueImageView storage_view{};
    bool is_framebuffer{};
    bool is_storage{};

    operator bool() const noexcept {
        return image_views[0].get();
    }
};

class Instance;
class RenderpassCache;
class DescriptorManager;
class Surface;

/**
 * Provides texture manipulation functions to the rasterizer cache
 * Separating this into a class makes it easier to abstract graphics API code
 */
class TextureRuntime {
    friend class Surface;
    friend class Sampler;

public:
    explicit TextureRuntime(const Instance& instance, Scheduler& scheduler,
                            RenderpassCache& renderpass_cache, DescriptorManager& desc_manager);
    ~TextureRuntime();

    void TickFrame();

    /// Destroys runtime cached resources
    void Reset();

    /// Maps an internal staging buffer of the provided size for pixel uploads/downloads
    VideoCore::StagingData FindStaging(u32 size, bool upload);

    /// Attempts to reinterpret a rectangle of source to another rectangle of dest
    bool Reinterpret(Surface& source, Surface& dest, const VideoCore::TextureBlit& blit);

    /// Fills the rectangle of the texture with the clear value provided
    bool ClearTexture(Surface& surface, const VideoCore::TextureClear& clear);

    /// Copies a rectangle of src_tex to another rectange of dst_rect
    bool CopyTextures(Surface& source, Surface& dest, const VideoCore::TextureCopy& copy);

    /// Blits a rectangle of src_tex to another rectange of dst_rect
    bool BlitTextures(Surface& surface, Surface& dest, const VideoCore::TextureBlit& blit);

    /// Generates mipmaps for all the available levels of the texture
    void GenerateMipmaps(Surface& surface);

    /// Returns true if the provided pixel format needs convertion
    [[nodiscard]] bool NeedsConversion(VideoCore::PixelFormat format) const;

    /// Returns a reference to the renderpass cache
    [[nodiscard]] RenderpassCache& GetRenderpassCache() {
        return renderpass_cache;
    }

private:
    /// Clears a partial texture rect using a clear rectangle
    void ClearTextureWithRenderpass(Surface& surface, const VideoCore::TextureClear& clear);

    /// Takes back ownership of the allocation for recycling
    void Destroy(Allocation&& alloc);

    /// Returns an allocation possibly resusing an existing one
    Allocation Allocate(const VideoCore::SurfaceParams& params,
                        const VideoCore::Material* material = nullptr);

    /// Returns the current Vulkan instance
    const Instance& GetInstance() const {
        return instance;
    }

    /// Returns the current Vulkan scheduler
    Scheduler& GetScheduler() const {
        return scheduler;
    }

private:
    const Instance& instance;
    Scheduler& scheduler;
    RenderpassCache& renderpass_cache;
    BlitHelper blit_helper;
    StreamBuffer upload_buffer;
    StreamBuffer download_buffer;
    std::deque<std::pair<u64, Allocation>> destroy_queue;
};

class Surface : public VideoCore::SurfaceBase {
    friend class TextureRuntime;

public:
    explicit Surface(TextureRuntime& runtime, const VideoCore::SurfaceParams& params);
    ~Surface();

    Surface(const Surface&) = delete;
    Surface& operator=(const Surface&) = delete;

    Surface(Surface&& o) noexcept = default;
    Surface& operator=(Surface&& o) noexcept = default;

    vk::ImageAspectFlags Aspect() const noexcept {
        return alloc.aspect;
    }

    /// Returns the image at index, otherwise the base image
    vk::Image Image(u32 index = 1) const noexcept;

    /// Returns the image view at index, otherwise the base view
    vk::ImageView ImageView(u32 index = 1) const noexcept;

    /// Returns the framebuffer view of the surface image
    vk::ImageView FramebufferView() noexcept;

    /// Returns the depth view of the surface image
    vk::ImageView DepthView() noexcept;

    /// Returns the stencil view of the surface image
    vk::ImageView StencilView() noexcept;

    /// Returns the R32 image view used for atomic load/store
    vk::ImageView StorageView() noexcept;

    /// Uploads pixel data in staging to a rectangle region of the surface texture
    void Upload(const VideoCore::BufferTextureCopy& upload, const VideoCore::StagingData& staging);

    /// Uploads the custom material to the surface allocation.
    void UploadCustom(const VideoCore::Material* material, u32 level);

    /// Downloads pixel data to staging from a rectangle region of the surface texture
    void Download(const VideoCore::BufferTextureCopy& download,
                  const VideoCore::StagingData& staging);

    /// Swaps the internal allocation to match the provided dimentions and format
    bool Swap(const VideoCore::Material* material);

    /// Returns the bpp of the internal surface format
    u32 GetInternalBytesPerPixel() const;

    /// Returns the access flags indicative of the surface
    vk::AccessFlags AccessFlags() const noexcept;

    /// Returns the pipeline stage flags indicative of the surface
    vk::PipelineStageFlags PipelineStageFlags() const noexcept;

private:
    /// Performs blit between the scaled/unscaled images
    void BlitScale(const VideoCore::TextureBlit& blit, bool up_scale);

    /// Downloads scaled depth stencil data
    void DepthStencilDownload(const VideoCore::BufferTextureCopy& download,
                              const VideoCore::StagingData& staging);

public:
    TextureRuntime* runtime;
    const Instance* instance;
    Scheduler* scheduler;
    const bool is_depth_stencil;
    Allocation alloc;
};

class Framebuffer : public VideoCore::FramebufferBase {
public:
    explicit Framebuffer(Surface* color, Surface* depth_stencil, vk::Rect2D render_area);
    explicit Framebuffer(TextureRuntime& runtime, Surface* color, u32 color_level,
                         Surface* depth_stencil, u32 depth_level, const Pica::Regs& regs,
                         Common::Rectangle<u32> surfaces_rect);
    ~Framebuffer();

    VideoCore::PixelFormat Format(VideoCore::SurfaceType type) const noexcept {
        return formats[Index(type)];
    }

    [[nodiscard]] vk::Image Image(VideoCore::SurfaceType type) const noexcept {
        return images[Index(type)];
    }

    [[nodiscard]] vk::ImageView ImageView(VideoCore::SurfaceType type) const noexcept {
        return image_views[Index(type)];
    }

    [[nodiscard]] vk::ImageView ShadowBuffer() const noexcept {
        return shadow_buffer;
    }

    bool HasAttachment(VideoCore::SurfaceType type) const noexcept {
        return has_attachment[Index(type)];
    }

    bool HasStencil() const noexcept {
        return Format(VideoCore::SurfaceType::DepthStencil) == VideoCore::PixelFormat::D24S8;
    }

    u32 Width() const noexcept {
        return width;
    }

    u32 Height() const noexcept {
        return height;
    }

    vk::Rect2D RenderArea() const noexcept {
        return render_area;
    }

private:
    void PrepareImages(Surface* color, Surface* depth_stencil);

private:
    bool shadow_rendering;
    std::array<vk::Image, 2> images{};
    std::array<vk::ImageView, 2> image_views{};
    std::array<bool, 2> has_attachment{};
    vk::ImageView shadow_buffer;
    std::array<VideoCore::PixelFormat, 2> formats{VideoCore::PixelFormat::Invalid,
                                                  VideoCore::PixelFormat::Invalid};
    vk::Rect2D render_area{};
    u32 width{};
    u32 height{};
};

class Sampler {
public:
    Sampler(TextureRuntime& runtime, const VideoCore::SamplerParams& params);
    ~Sampler();

    Sampler(const Sampler&) = delete;
    Sampler& operator=(const Sampler&) = delete;

    Sampler(Sampler&& o) noexcept = default;
    Sampler& operator=(Sampler&& o) noexcept = default;

    [[nodiscard]] vk::Sampler Handle() const noexcept {
        return sampler.get();
    }

private:
    vk::UniqueSampler sampler;
};

struct Traits {
    using Runtime = Vulkan::TextureRuntime;
    using Surface = Vulkan::Surface;
    using Sampler = Vulkan::Sampler;
    using Framebuffer = Vulkan::Framebuffer;
};

using RasterizerCache = VideoCore::RasterizerCache<Traits>;

} // namespace Vulkan
