// Copyright 2023 Citra Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#include <algorithm>
#include <memory>
#include <string>
#include <vector>
#include "audio_core/input_details.h"
#include "audio_core/static_input.h"
#include "common/logging/log.h"
#include "core/core.h"

namespace AudioCore {
namespace {
struct InputDetails {
    using FactoryFn = std::unique_ptr<Input> (*)(std::string_view);
    using ListDevicesFn = std::vector<std::string> (*)();

    /// Type of this input.
    InputType type;
    /// Name for this input.
    std::string_view name;
    /// A method to call to construct an instance of this type of input.
    FactoryFn factory;
    /// A method to call to list available devices.
    ListDevicesFn list_devices;
};

// input_details is ordered in terms of desirability, with the best choice at the top.
constexpr std::array input_details = {
    InputDetails{
        InputType::Static, "Static Noise", [](std::string_view device_id) -> std::unique_ptr<Input> {
            return std::make_unique<StaticInput>();
        }, [] {
            return std::vector<std::string>{"Static Noise"};
        }
    }
};

const InputDetails& GetInputDetails(InputType input_type) {
    auto iter = std::find_if(
        input_details.begin(), input_details.end(),
        [input_type](const auto& input_detail) { return input_detail.type == input_type; });

    if (input_type == InputType::Auto || iter == input_details.end()) {
        if (input_type != InputType::Auto) {
            LOG_ERROR(Audio, "AudioCore::GetInputDetails given invalid input_type {}", input_type);
        }
        // Auto-select.
        // input_details is ordered in terms of desirability, with the best choice at the front.
        iter = input_details.begin();
    }

    return *iter;
}
} // Anonymous namespace

std::string_view GetInputName(InputType input_type) {
    if (input_type == InputType::Auto) {
        return "Auto";
    }
    return GetInputDetails(input_type).name;
}

std::vector<std::string> GetDeviceListForInput(InputType input_type) {
    return GetInputDetails(input_type).list_devices();
}

std::unique_ptr<Input> CreateInputFromID(InputType input_type, std::string_view device_id) {
    return GetInputDetails(input_type).factory(device_id);
}

} // namespace AudioCore
