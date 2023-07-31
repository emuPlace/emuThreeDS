// Copyright 2017 Citra Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#include <algorithm>
#include <cstring>
#include "common/arch.h"
#include "common/assert.h"
#include "common/scm_rev.h"
#include "common/telemetry.h"

namespace Common::Telemetry {

void FieldCollection::Accept(VisitorInterface& visitor) const {
    for (const auto& field : fields) {
        field.second->Accept(visitor);
    }
}

void FieldCollection::AddField(std::unique_ptr<FieldInterface> field) {
    fields[field->GetName()] = std::move(field);
}

template <class T>
void Field<T>::Accept(VisitorInterface& visitor) const {
    visitor.Visit(*this);
}

template class Field<bool>;
template class Field<double>;
template class Field<float>;
template class Field<u8>;
template class Field<u16>;
template class Field<u32>;
template class Field<u64>;
template class Field<s8>;
template class Field<s16>;
template class Field<s32>;
template class Field<s64>;
template class Field<std::string>;
template class Field<const char*>;
template class Field<std::chrono::microseconds>;

void AppendBuildInfo(FieldCollection& fc) {
    const bool is_git_dirty{std::strstr(Common::g_scm_desc, "dirty") != nullptr};
    fc.AddField(FieldType::App, "Git_IsDirty", is_git_dirty);
    fc.AddField(FieldType::App, "Git_Branch", Common::g_scm_branch);
    fc.AddField(FieldType::App, "Git_Revision", Common::g_scm_rev);
    fc.AddField(FieldType::App, "BuildDate", Common::g_build_date);
    fc.AddField(FieldType::App, "BuildName", Common::g_build_name);
}

void AppendCPUInfo(FieldCollection& fc) {
    fc.AddField(FieldType::UserSystem, "CPU_Model", "Other");
}

void AppendOSInfo(FieldCollection& fc) {
    fc.AddField(FieldType::UserSystem, "OsPlatform", "Apple");
}

} // namespace Common::Telemetry
