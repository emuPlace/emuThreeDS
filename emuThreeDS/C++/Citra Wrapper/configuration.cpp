//
//  configuration.cpp
//  emuThreeDS
//
//  Created by Antique on 18/6/2023.
//

#include "configuration.h"

#include <iomanip>
#include <memory>
#include <sstream>
#include <unordered_map>
#include <inih/INIReader.h>
#include "common/file_util.h"
#include "common/logging/log.h"
#include "common/param_package.h"
#include "common/settings.h"
#include "core/hle/service/service.h"
#include "network/network_settings.h"

Configuration::Configuration() {
    // TODO: Don't hardcode the path; let the frontend decide where to put the config files.
    configuration_loc = FileUtil::GetUserPath(FileUtil::UserPath::ConfigDir) + "sdl2-config.ini";
    configuration = std::make_unique<INIReader>(configuration_loc);

    Reload();
}

Configuration::~Configuration() = default;

bool Configuration::LoadINI(const std::string& default_contents, bool retry) {
    const std::string& location = this->configuration_loc;
    if (configuration->ParseError() < 0) {
        if (retry) {
            LOG_WARNING(Config, "Failed to load {}. Creating file from defaults...", location);
            FileUtil::CreateFullPath(location);
            FileUtil::WriteStringToFile(true, location, default_contents);
            configuration = std::make_unique<INIReader>(location); // Reopen file

            return LoadINI(default_contents, false);
        }
        LOG_ERROR(Config, "Failed.");
        return false;
    }
    LOG_INFO(Config, "Successfully loaded {}", location);
    return true;
}

template <>
void Configuration::ReadSetting(const std::string& group, Settings::Setting<std::string>& setting) {
    std::string setting_value = configuration->Get(group, setting.GetLabel(), setting.GetDefault());
    if (setting_value.empty()) {
        setting_value = setting.GetDefault();
    }
    setting = std::move(setting_value);
}

template <>
void Configuration::ReadSetting(const std::string& group, Settings::Setting<bool>& setting) {
    setting = configuration->GetBoolean(group, setting.GetLabel(), setting.GetDefault());
}

template <typename Type, bool ranged>
void Configuration::ReadSetting(const std::string& group, Settings::Setting<Type, ranged>& setting) {
    if constexpr (std::is_floating_point_v<Type>) {
        setting = static_cast<Type>(
            configuration->GetReal(group, setting.GetLabel(), setting.GetDefault()));
    } else {
        setting = static_cast<Type>(configuration->GetInteger(
            group, setting.GetLabel(), static_cast<long>(setting.GetDefault())));
    }
}

void Configuration::ReadValues() {
    Settings::values.current_input_profile.motion_device = configuration->GetString(
        "Controls", "motion_device",
        "engine:motion_emu,update_period:100,sensitivity:0.01,tilt_clamp:90.0");
    Settings::values.current_input_profile.touch_device =
        configuration->GetString("Controls", "touch_device", "engine:emu_window");
    //Settings::values.current_input_profile.udp_input_address = configuration->GetString(
    //    "Controls", "udp_input_address", InputCommon::CemuhookUDP::DEFAULT_ADDR);
    //Settings::values.current_input_profile.udp_input_port =
    //    static_cast<u16>(configuration->GetInteger("Controls", "udp_input_port",
    //                                             InputCommon::CemuhookUDP::DEFAULT_PORT));

    // Core
    ReadSetting("Core", Settings::values.use_cpu_jit);
    ReadSetting("Core", Settings::values.cpu_clock_percentage);

    // Renderer
    ReadSetting("Renderer", Settings::values.graphics_api);
    ReadSetting("Renderer", Settings::values.physical_device);
    ReadSetting("Renderer", Settings::values.spirv_shader_gen);
    ReadSetting("Renderer", Settings::values.async_shader_compilation);
    ReadSetting("Renderer", Settings::values.async_presentation);
    ReadSetting("Renderer", Settings::values.use_gles);
    ReadSetting("Renderer", Settings::values.use_hw_shader);
    ReadSetting("Renderer", Settings::values.shaders_accurate_mul);
    ReadSetting("Renderer", Settings::values.use_shader_jit);
    ReadSetting("Renderer", Settings::values.resolution_factor);
    ReadSetting("Renderer", Settings::values.use_disk_shader_cache);
    ReadSetting("Renderer", Settings::values.frame_limit);
    ReadSetting("Renderer", Settings::values.use_vsync_new);
    ReadSetting("Renderer", Settings::values.texture_filter);

    ReadSetting("Renderer", Settings::values.mono_render_option);
    ReadSetting("Renderer", Settings::values.render_3d);
    ReadSetting("Renderer", Settings::values.factor_3d);
    ReadSetting("Renderer", Settings::values.pp_shader_name);
    ReadSetting("Renderer", Settings::values.anaglyph_shader_name);
    ReadSetting("Renderer", Settings::values.filter_mode);

    ReadSetting("Renderer", Settings::values.bg_red);
    ReadSetting("Renderer", Settings::values.bg_green);
    ReadSetting("Renderer", Settings::values.bg_blue);

    // Layout
    ReadSetting("Layout", Settings::values.layout_option);
    ReadSetting("Layout", Settings::values.swap_screen);
    ReadSetting("Layout", Settings::values.upright_screen);
    ReadSetting("Layout", Settings::values.large_screen_proportion);
    ReadSetting("Layout", Settings::values.custom_layout);
    ReadSetting("Layout", Settings::values.custom_top_left);
    ReadSetting("Layout", Settings::values.custom_top_top);
    ReadSetting("Layout", Settings::values.custom_top_right);
    ReadSetting("Layout", Settings::values.custom_top_bottom);
    ReadSetting("Layout", Settings::values.custom_bottom_left);
    ReadSetting("Layout", Settings::values.custom_bottom_top);
    ReadSetting("Layout", Settings::values.custom_bottom_right);
    ReadSetting("Layout", Settings::values.custom_bottom_bottom);
    ReadSetting("Layout", Settings::values.custom_second_layer_opacity);

    // Utility
    ReadSetting("Utility", Settings::values.dump_textures);
    ReadSetting("Utility", Settings::values.custom_textures);
    ReadSetting("Utility", Settings::values.preload_textures);
    ReadSetting("Utility", Settings::values.async_custom_loading);

    // Audio
    ReadSetting("Audio", Settings::values.audio_emulation);
    ReadSetting("Audio", Settings::values.enable_audio_stretching);
    ReadSetting("Audio", Settings::values.volume);
    ReadSetting("Audio", Settings::values.output_type);
    ReadSetting("Audio", Settings::values.output_device);
    ReadSetting("Audio", Settings::values.input_type);
    ReadSetting("Audio", Settings::values.input_device);

    // Data Storage
    ReadSetting("Data Storage", Settings::values.use_virtual_sd);
    ReadSetting("Data Storage", Settings::values.use_custom_storage);

    if (Settings::values.use_custom_storage) {
        FileUtil::UpdateUserPath(FileUtil::UserPath::NANDDir,
                                 configuration->GetString("Data Storage", "nand_directory", ""));
        FileUtil::UpdateUserPath(FileUtil::UserPath::SDMCDir,
                                 configuration->GetString("Data Storage", "sdmc_directory", ""));
    }

    // System
    ReadSetting("System", Settings::values.is_new_3ds);
    ReadSetting("System", Settings::values.region_value);
    ReadSetting("System", Settings::values.init_clock);
    {
        std::tm t;
        t.tm_sec = 1;
        t.tm_min = 0;
        t.tm_hour = 0;
        t.tm_mday = 1;
        t.tm_mon = 0;
        t.tm_year = 100;
        t.tm_isdst = 0;
        std::istringstream string_stream(
            configuration->GetString("System", "init_time", "2000-01-01 00:00:01"));
        string_stream >> std::get_time(&t, "%Y-%m-%d %H:%M:%S");
        if (string_stream.fail()) {
            LOG_ERROR(Config, "Failed To parse init_time. Using 2000-01-01 00:00:01");
        }
        Settings::values.init_time =
            std::chrono::duration_cast<std::chrono::seconds>(
                std::chrono::system_clock::from_time_t(std::mktime(&t)).time_since_epoch())
                .count();
    }
    ReadSetting("System", Settings::values.plugin_loader_enabled);
    ReadSetting("System", Settings::values.allow_plugin_loader);

    {
        constexpr const char* default_init_time_offset = "0 00:00:00";

        std::string offset_string =
            configuration->GetString("System", "init_time_offset", default_init_time_offset);

        size_t sep_index = offset_string.find(' ');

        if (sep_index == std::string::npos) {
            LOG_ERROR(Config, "Failed to parse init_time_offset. Using 0 00:00:00");
            offset_string = default_init_time_offset;

            sep_index = offset_string.find(' ');
        }

        std::string day_string = offset_string.substr(0, sep_index);
        long long days = 0;

        try {
            days = std::stoll(day_string);
        } catch (std::logic_error&) {
            LOG_ERROR(Config, "Failed to parse days in init_time_offset. Using 0");
            days = 0;
        }

        long long days_in_seconds = days * 86400;

        std::tm t;
        t.tm_sec = 0;
        t.tm_min = 0;
        t.tm_hour = 0;
        t.tm_mday = 1;
        t.tm_mon = 0;
        t.tm_year = 100;
        t.tm_isdst = 0;

        std::istringstream string_stream(offset_string.substr(sep_index + 1));
        string_stream >> std::get_time(&t, "%H:%M:%S");

        if (string_stream.fail()) {
            LOG_ERROR(Config,
                      "Failed to parse hours, minutes and seconds in init_time_offset. 00:00:00");
        }

        auto time_offset =
            std::chrono::system_clock::from_time_t(std::mktime(&t)).time_since_epoch();

        auto secs = std::chrono::duration_cast<std::chrono::seconds>(time_offset).count();

        Settings::values.init_time_offset = static_cast<long long>(secs) + days_in_seconds;
    }

    // Camera
    using namespace Service::CAM;
    Settings::values.camera_name[OuterRightCamera] =
        configuration->GetString("Camera", "camera_outer_right_name", "blank");
    Settings::values.camera_config[OuterRightCamera] =
        configuration->GetString("Camera", "camera_outer_right_config", "");
    Settings::values.camera_flip[OuterRightCamera] =
        configuration->GetInteger("Camera", "camera_outer_right_flip", 0);
    Settings::values.camera_name[InnerCamera] =
        configuration->GetString("Camera", "camera_inner_name", "blank");
    Settings::values.camera_config[InnerCamera] =
        configuration->GetString("Camera", "camera_inner_config", "");
    Settings::values.camera_flip[InnerCamera] =
        configuration->GetInteger("Camera", "camera_inner_flip", 0);
    Settings::values.camera_name[OuterLeftCamera] =
        configuration->GetString("Camera", "camera_outer_left_name", "blank");
    Settings::values.camera_config[OuterLeftCamera] =
        configuration->GetString("Camera", "camera_outer_left_config", "");
    Settings::values.camera_flip[OuterLeftCamera] =
        configuration->GetInteger("Camera", "camera_outer_left_flip", 0);

    // Miscellaneous
    ReadSetting("Miscellaneous", Settings::values.log_filter);

    // Debugging
    Settings::values.record_frame_times =
        configuration->GetBoolean("Debugging", "record_frame_times", false);
    ReadSetting("Debugging", Settings::values.renderer_debug);
    ReadSetting("Debugging", Settings::values.use_gdbstub);
    ReadSetting("Debugging", Settings::values.gdbstub_port);

    for (const auto& service_module : Service::service_module_map) {
        bool use_lle = configuration->GetBoolean("Debugging", "LLE\\" + service_module.name, false);
        Settings::values.lle_modules.emplace(service_module.name, use_lle);
    }

    // Web Service
    NetSettings::values.enable_telemetry =
        configuration->GetBoolean("WebService", "enable_telemetry", true);
    NetSettings::values.web_api_url =
        configuration->GetString("WebService", "web_api_url", "https://api.citra-emu.org");
    NetSettings::values.citra_username = configuration->GetString("WebService", "citra_username", "");
    NetSettings::values.citra_token = configuration->GetString("WebService", "citra_token", "");

    // Video Dumping
    Settings::values.output_format =
        configuration->GetString("Video Dumping", "output_format", "webm");
    Settings::values.format_options = configuration->GetString("Video Dumping", "format_options", "");

    Settings::values.video_encoder =
        configuration->GetString("Video Dumping", "video_encoder", "libvpx-vp9");

    // Options for variable bit rate live streaming taken from here:
    // https://developers.google.com/media/vp9/live-encoding
    std::string default_video_options;
    if (Settings::values.video_encoder == "libvpx-vp9") {
        default_video_options =
            "quality:realtime,speed:6,tile-columns:4,frame-parallel:1,threads:8,row-mt:1";
    }
    Settings::values.video_encoder_options =
        configuration->GetString("Video Dumping", "video_encoder_options", default_video_options);
    Settings::values.video_bitrate =
        configuration->GetInteger("Video Dumping", "video_bitrate", 2500000);

    Settings::values.audio_encoder =
        configuration->GetString("Video Dumping", "audio_encoder", "libvorbis");
    Settings::values.audio_encoder_options =
        configuration->GetString("Video Dumping", "audio_encoder_options", "");
    Settings::values.audio_bitrate =
        configuration->GetInteger("Video Dumping", "audio_bitrate", 64000);
}

void Configuration::Reload() {
    // LoadINI(DefaultINI::configuration_file);
    ReadValues();
}
