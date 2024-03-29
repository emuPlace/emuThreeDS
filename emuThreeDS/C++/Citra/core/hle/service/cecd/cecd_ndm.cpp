// Copyright 2016 Citra Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#include "common/archives.h"
#include "core/hle/service/cecd/cecd_ndm.h"

SERIALIZE_EXPORT_IMPL(Service::CECD::CECD_NDM)

namespace Service::CECD {

CECD_NDM::CECD_NDM(std::shared_ptr<Module> cecd)
    : Module::Interface(std::move(cecd), "cecd:ndm", DefaultMaxSessions) {
    static const FunctionInfo functions[] = {
        // clang-format off
        {IPC::MakeHeader(0x0001, 0, 0), nullptr, "Initialize"},
        {IPC::MakeHeader(0x0002, 0, 0), nullptr, "Deinitialize"},
        {IPC::MakeHeader(0x0003, 0, 0), nullptr, "ResumeDaemon"},
        {IPC::MakeHeader(0x0004, 1, 0), nullptr, "SuspendDaemon"},
        // clang-format on
    };

    RegisterHandlers(functions);
}

} // namespace Service::CECD
