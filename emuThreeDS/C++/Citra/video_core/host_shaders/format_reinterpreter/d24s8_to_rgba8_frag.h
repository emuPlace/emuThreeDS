// Copyright 2022 Citra Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#pragma once

#include <string_view>

namespace HostShaders {

constexpr std::string_view D24S8_TO_RGBA8_FRAG = {
"// Copyright 2023 Citra Emulator Project\n"
"// Licensed under GPLv2 or any later version\n"
"// Refer to the license.txt file included.\n"
"\n"
"//? #version 430 core\n"
"\n"
"layout(location = 0) in mediump vec2 tex_coord;\n"
"layout(location = 0) out lowp vec4 frag_color;\n"
"\n"
"layout(binding = 0) uniform highp sampler2D depth;\n"
"layout(binding = 1) uniform lowp usampler2D stencil;\n"
"\n"
"void main() {\n"
"    mediump vec2 coord = tex_coord * vec2(textureSize(depth, 0));\n"
"    mediump ivec2 tex_icoord = ivec2(coord);\n"
"    highp uint depth_val =\n"
"        uint(texelFetch(depth, tex_icoord, 0).x * (exp2(32.0) - 1.0));\n"
"    lowp uint stencil_val = texelFetch(stencil, tex_icoord, 0).x;\n"
"    highp uvec4 components =\n"
"        uvec4(stencil_val, (uvec3(depth_val) >> uvec3(24u, 16u, 8u)) & 0x000000FFu);\n"
"    frag_color = vec4(components) / (exp2(8.0) - 1.0);\n"
"}\n"
"\n"

};

} // namespace HostShaders
