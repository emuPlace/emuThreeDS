// Copyright 2022 Citra Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#pragma once

#include <string_view>

namespace HostShaders {

constexpr std::string_view NEAREST_NEIGHBOR_FRAG = {
"// Copyright 2023 Citra Emulator Project\n"
"// Licensed under GPLv2 or any later version\n"
"// Refer to the license.txt file included.\n"
"\n"
"//? #version 430 core\n"
"precision mediump float;\n"
"\n"
"layout(location = 0) in vec2 tex_coord;\n"
"layout(location = 0) out vec4 frag_color;\n"
"\n"
"layout(binding = 2) uniform sampler2D input_texture;\n"
"\n"
"void main() {\n"
"    frag_color = texture(input_texture, tex_coord);\n"
"}\n"
"\n"

};

} // namespace HostShaders
