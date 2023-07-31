// Copyright 2023 Citra Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#pragma once

#include <compare>
#include <cstring>
#include <mutex>
#include <variant>
#include "common/hash.h"
#include "video_core/rasterizer_cache/pixel_format.h"
#include "video_core/renderer_vulkan/vk_common.h"

namespace Vulkan {

class Instance;
class Scheduler;
class Surface;

struct FramebufferInfo {
    vk::ImageView color;
    vk::ImageView depth;
    u32 width = 1;
    u32 height = 1;

    bool operator==(const FramebufferInfo& other) const noexcept {
        return std::tie(color, depth, width, height) ==
               std::tie(other.color, other.depth, other.width, other.height);
    }

    struct Hash {
        const u64 operator()(const FramebufferInfo& info) const {
            return Common::ComputeHash64(&info, sizeof(FramebufferInfo));
        }
    };
};

struct RenderTarget {
    vk::ImageAspectFlags aspect;
    vk::Image image;
    vk::ImageView image_view;

    operator bool() const noexcept {
        return image_view;
    }

    bool operator==(const RenderTarget& other) const {
        return image_view == other.image_view;
    }
};

struct RenderingInfo {
    RenderTarget color;
    RenderTarget depth;
    vk::Rect2D render_area;
    vk::ClearValue clear;
    bool do_clear;

    bool operator==(const RenderingInfo& other) const {
        return color == other.color && depth == other.depth && render_area == other.render_area &&
               do_clear == other.do_clear &&
               std::memcmp(&clear, &other.clear, sizeof(vk::ClearValue)) == 0;
    }
};

class Framebuffer;

class RenderpassCache {
    static constexpr std::size_t MAX_COLOR_FORMATS = 5;
    static constexpr std::size_t MAX_DEPTH_FORMATS = 4;

public:
    explicit RenderpassCache(const Instance& instance, Scheduler& scheduler);
    ~RenderpassCache();

    /// Destroys cached framebuffers
    void ClearFramebuffers();

    /// Begins a new renderpass only when no other renderpass is currently active
    void BeginRendering(const Framebuffer& framebuffer, bool do_clear = false,
                        vk::ClearValue clear = {});

    /// Exits from any currently active renderpass instance
    void EndRendering();

    /// Creates the renderpass used when rendering to the swapchain
    void CreatePresentRenderpass(vk::Format format);

    /// Returns the renderpass associated with the color-depth format pair
    vk::RenderPass GetRenderpass(VideoCore::PixelFormat color, VideoCore::PixelFormat depth,
                                 bool is_clear);

private:
    /// Begins a new rendering scope using dynamic rendering
    void DynamicRendering(const Framebuffer& framebuffer);

    /// Begins a new rendering scope using renderpasses
    void EnterRenderpass(const Framebuffer& framebuffer);

    /// Creates a renderpass configured appropriately and stores it in cached_renderpasses
    vk::RenderPass CreateRenderPass(vk::Format color, vk::Format depth,
                                    vk::AttachmentLoadOp load_op, vk::ImageLayout initial_layout,
                                    vk::ImageLayout final_layout) const;

    /// Creates a new Vulkan framebuffer object
    vk::Framebuffer CreateFramebuffer(const FramebufferInfo& info, vk::RenderPass renderpass);

private:
    const Instance& instance;
    Scheduler& scheduler;
    vk::RenderPass cached_renderpasses[MAX_COLOR_FORMATS + 1][MAX_DEPTH_FORMATS + 1][2];
    std::unordered_map<FramebufferInfo, vk::Framebuffer, FramebufferInfo::Hash> framebuffers;
    RenderingInfo info{};
    bool rendering = false;
    bool dynamic_rendering = false;
    u32 cmd_count{};
    std::mutex cache_mutex;
};

} // namespace Vulkan
