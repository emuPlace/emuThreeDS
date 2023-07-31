// Copyright 2022 Citra Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#pragma once

#include <string_view>

namespace HostShaders {

constexpr std::string_view OPENGL_PRESENT_ANAGLYPH_FRAG = {
"// Copyright 2023 Citra Emulator Project\n"
"// Licensed under GPLv2 or any later version\n"
"// Refer to the license.txt file included.\n"
"\n"
"//? #version 430 core\n"
"\n"
"// Anaglyph Red-Cyan shader based on Dubois algorithm\n"
"// Constants taken from the paper:\n"
"// 'Conversion of a Stereo Pair to Anaglyph with\n"
"// the Least-Squares Projection Method'\n"
"// Eric Dubois, March 2009\n"
"const mat3 l = mat3( 0.437, 0.449, 0.164,\n"
"              -0.062,-0.062,-0.024,\n"
"              -0.048,-0.050,-0.017);\n"
"const mat3 r = mat3(-0.011,-0.032,-0.007,\n"
"               0.377, 0.761, 0.009,\n"
"              -0.026,-0.093, 1.234);\n"
"\n"
"layout(location = 0) in vec2 frag_tex_coord;\n"
"layout(location = 0) out vec4 color;\n"
"\n"
"layout(binding = 0) uniform sampler2D color_texture;\n"
"layout(binding = 1) uniform sampler2D color_texture_r;\n"
"\n"
"uniform vec4 resolution;\n"
"uniform int layer;\n"
"\n"
"void main() {\n"
"    vec4 color_tex_l = texture(color_texture, frag_tex_coord);\n"
"    vec4 color_tex_r = texture(color_texture_r, frag_tex_coord);\n"
"    color = vec4(color_tex_l.rgb*l+color_tex_r.rgb*r, color_tex_l.a);\n"
"}\n"
"\n"

};

} // namespace HostShaders
