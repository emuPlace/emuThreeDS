// Copyright 2023 Citra Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#pragma once

#include <span>
#include "video_core/renderer_vulkan/vk_common.h"

namespace Vulkan {

enum class ShaderOptimization { Normal = 0, Debug = 1 };

vk::ShaderModule Compile(std::string_view code, vk::ShaderStageFlagBits stage, vk::Device device,
                         ShaderOptimization level);

vk::ShaderModule CompileSPV(std::span<const u32> code, vk::Device device);

} // namespace Vulkan
