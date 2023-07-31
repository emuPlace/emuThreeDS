// Copyright 2022 Citra Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#pragma once

#include <string_view>

namespace HostShaders {

constexpr std::string_view BICUBIC_FRAG = {
"// Copyright 2023 Citra Emulator Project\n"
"// Licensed under GPLv2 or any later version\n"
"// Refer to the license.txt file included.\n"
"\n"
"//? #version 330\n"
"precision mediump float;\n"
"\n"
"layout(location = 0) in vec2 tex_coord;\n"
"layout(location = 0) out vec4 frag_color;\n"
"\n"
"layout(binding = 0) uniform sampler2D input_texture;\n"
"\n"
"// from http://www.java-gaming.org/index.php?topic=35123.0\n"
"vec4 cubic(float v) {\n"
"    vec4 n = vec4(1.0, 2.0, 3.0, 4.0) - v;\n"
"    vec4 s = n * n * n;\n"
"    float x = s.x;\n"
"    float y = s.y - 4.0 * s.x;\n"
"    float z = s.z - 4.0 * s.y + 6.0 * s.x;\n"
"    float w = 6.0 - x - y - z;\n"
"    return vec4(x, y, z, w) * (1.0 / 6.0);\n"
"}\n"
"\n"
"vec4 textureBicubic(sampler2D tex_sampler, vec2 texCoords) {\n"
"    vec2 texSize = vec2(textureSize(tex_sampler, 0));\n"
"    vec2 invTexSize = 1.0 / texSize;\n"
"\n"
"    texCoords = texCoords * texSize - 0.5;\n"
"\n"
"    vec2 fxy = fract(texCoords);\n"
"    texCoords -= fxy;\n"
"\n"
"    vec4 xcubic = cubic(fxy.x);\n"
"    vec4 ycubic = cubic(fxy.y);\n"
"\n"
"    vec4 c = texCoords.xxyy + vec2(-0.5, +1.5).xyxy;\n"
"\n"
"    vec4 s = vec4(xcubic.xz + xcubic.yw, ycubic.xz + ycubic.yw);\n"
"    vec4 offset = c + vec4(xcubic.yw, ycubic.yw) / s;\n"
"\n"
"    offset *= invTexSize.xxyy;\n"
"\n"
"    vec4 sample0 = texture(tex_sampler, offset.xz);\n"
"    vec4 sample1 = texture(tex_sampler, offset.yz);\n"
"    vec4 sample2 = texture(tex_sampler, offset.xw);\n"
"    vec4 sample3 = texture(tex_sampler, offset.yw);\n"
"\n"
"    float sx = s.x / (s.x + s.y);\n"
"    float sy = s.z / (s.z + s.w);\n"
"\n"
"    return mix(mix(sample3, sample2, sx), mix(sample1, sample0, sx), sy);\n"
"}\n"
"\n"
"void main() {\n"
"    frag_color = textureBicubic(input_texture, tex_coord);\n"
"}\n"
"\n"

};

} // namespace HostShaders
