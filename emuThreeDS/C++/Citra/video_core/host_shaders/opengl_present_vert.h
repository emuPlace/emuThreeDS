// Copyright 2022 Citra Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#pragma once

#include <string_view>

namespace HostShaders {

constexpr std::string_view OPENGL_PRESENT_VERT = {
"// Copyright 2023 Citra Emulator Project\n"
"// Licensed under GPLv2 or any later version\n"
"// Refer to the license.txt file included.\n"
"\n"
"//? #version 430 core\n"
"layout(location = 0) in vec2 vert_position;\n"
"layout(location = 1) in vec2 vert_tex_coord;\n"
"layout(location = 0) out vec2 frag_tex_coord;\n"
"\n"
"// This is a truncated 3x3 matrix for 2D transformations:\n"
"// The upper-left 2x2 submatrix performs scaling/rotation/mirroring.\n"
"// The third column performs translation.\n"
"// The third row could be used for projection, which we don't need in 2D. It hence is assumed to\n"
"// implicitly be [0, 0, 1]\n"
"uniform mat3x2 modelview_matrix;\n"
"\n"
"void main() {\n"
"    // Multiply input position by the rotscale part of the matrix and then manually translate by\n"
"    // the last column. This is equivalent to using a full 3x3 matrix and expanding the vector\n"
"    // to `vec3(vert_position.xy, 1.0)`\n"
"    gl_Position = vec4(mat2(modelview_matrix) * vert_position + modelview_matrix[2], 0.0, 1.0);\n"
"    frag_tex_coord = vert_tex_coord;\n"
"}\n"
"\n"

};

} // namespace HostShaders
