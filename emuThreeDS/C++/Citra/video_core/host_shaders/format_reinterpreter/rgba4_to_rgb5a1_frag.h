// Copyright 2022 Citra Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#pragma once

#include <string_view>

namespace HostShaders {

constexpr std::string_view RGBA4_TO_RGB5A1_FRAG = {
"// Copyright 2023 Citra Emulator Project\n"
"// Licensed under GPLv2 or any later version\n"
"// Refer to the license.txt file included.\n"
"\n"
"//? #version 430 core\n"
"\n"
"layout(location = 0) in mediump vec2 tex_coord;\n"
"layout(location = 0) out lowp vec4 frag_color;\n"
"\n"
"layout(binding = 0) uniform lowp sampler2D source;\n"
"\n"
"void main() {\n"
"    mediump vec2 coord = tex_coord * vec2(textureSize(source, 0));\n"
"    mediump ivec2 tex_icoord = ivec2(coord);\n"
"    lowp ivec4 rgba4 = ivec4(texelFetch(source, tex_icoord, 0) * (exp2(4.0) - 1.0));\n"
"    lowp ivec3 rgb5 =\n"
"        ((rgba4.rgb << ivec3(1, 2, 3)) | (rgba4.gba >> ivec3(3, 2, 1))) & 0x1F;\n"
"    frag_color = vec4(vec3(rgb5) / (exp2(5.0) - 1.0), rgba4.a & 0x01);\n"
"}\n"
"\n"

};

} // namespace HostShaders
