// Copyright 2022 Citra Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#pragma once

#include <string_view>

namespace HostShaders {

constexpr std::string_view X_GRADIENT_FRAG = {
"// MIT License\n"
"//\n"
"// Copyright (c) 2019 bloc97\n"
"//\n"
"// Permission is hereby granted, free of charge, to any person obtaining a copy\n"
"// of this software and associated documentation files (the 'Software'), to deal\n"
"// in the Software without restriction, including without limitation the rights\n"
"// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell\n"
"// copies of the Software, and to permit persons to whom the Software is\n"
"// furnished to do so, subject to the following conditions:\n"
"//\n"
"// The above copyright notice and this permission notice shall be included in all\n"
"// copies or substantial portions of the Software.\n"
"//\n"
"// THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\n"
"// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\n"
"// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\n"
"// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\n"
"// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\n"
"// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE\n"
"// SOFTWARE.\n"
"\n"
"//? #version 430 core\n"
"precision mediump float;\n"
"\n"
"layout(location = 0) in vec2 tex_coord;\n"
"layout(location = 0) out vec2 frag_color;\n"
"\n"
"layout(binding = 0) uniform sampler2D tex_input;\n"
"\n"
"const vec3 K = vec3(0.2627, 0.6780, 0.0593);\n"
"// TODO: improve handling of alpha channel\n"
"#define GetLum(xoffset) dot(K, textureLodOffset(tex_input, tex_coord, 0.0, ivec2(xoffset, 0)).rgb)\n"
"\n"
"void main() {\n"
"    float l = GetLum(-1);\n"
"    float c = GetLum(0);\n"
"    float r = GetLum(1);\n"
"\n"
"    frag_color = vec2(r - l, l + 2.0 * c + r);\n"
"}\n"
"\n"

};

} // namespace HostShaders
