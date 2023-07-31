// Copyright 2022 Citra Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#pragma once

#include <string_view>

namespace HostShaders {

constexpr std::string_view OPENGL_PRESENT_FRAG = {
"// Copyright 2023 Citra Emulator Project\n"
"// Licensed under GPLv2 or any later version\n"
"// Refer to the license.txt file included.\n"
"\n"
"//? #version 430 core\n"
"\n"
"layout(location = 0) in vec2 frag_tex_coord;\n"
"layout(location = 0) out vec4 color;\n"
"\n"
"layout(binding = 0) uniform sampler2D color_texture;\n"
"\n"
"uniform vec4 i_resolution;\n"
"uniform vec4 o_resolution;\n"
"uniform int layer;\n"
"\n"
"void main() {\n"
"    color = texture(color_texture, frag_tex_coord);\n"
"}\n"
"\n"

};

} // namespace HostShaders
