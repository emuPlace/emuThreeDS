// Copyright 2018 Citra Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#include <cryptopp/aes.h>
#include <cryptopp/modes.h>
#include "common/archives.h"
#include "common/logging/log.h"
#include "core/core.h"
#include "core/hle/ipc_helpers.h"
#include "core/hle/service/ps/ps_ps.h"
#include "core/hw/aes/arithmetic128.h"
#include "core/hw/aes/key.h"

SERIALIZE_EXPORT_IMPL(Service::PS::PS_PS)

namespace Service::PS {

enum class AlgorithmType : u8 {
    CBC_Encrypt,
    CBC_Decrypt,
    CTR_Encrypt,
    CTR_Decrypt,
    CCM_Encrypt,
    CCM_Decrypt,
};

constexpr std::array<u8, 10> KeyTypes{{
    HW::AES::SSLKey,
    HW::AES::UDSDataKey,
    HW::AES::APTWrap,
    HW::AES::BOSSDataKey,
    0x32, // unknown
    HW::AES::DLPNFCDataKey,
    HW::AES::CECDDataKey,
    0, // invalid
    HW::AES::FRDKey,
    // Note: According to 3dbrew the KeyY is overridden by Process9 when using this key type.
    HW::AES::DLPNFCDataKey,
}};

void PS_PS::EncryptDecryptAes(Kernel::HLERequestContext& ctx) {
    IPC::RequestParser rp(ctx, 0x4, 8, 4);
    auto src_size = rp.Pop<u32>();
    [[maybe_unused]] const auto dest_size = rp.Pop<u32>();

    using CryptoPP::AES;
    std::array<u8, AES::BLOCKSIZE> iv;
    rp.PopRaw(iv);

    AlgorithmType algorithm = rp.PopEnum<AlgorithmType>();
    u8 key_type = rp.Pop<u8>();
    auto source = rp.PopMappedBuffer();
    auto destination = rp.PopMappedBuffer();

    LOG_DEBUG(Service_PS, "called algorithm={} key_type={}", algorithm, key_type);

    // TODO(zhaowenlan1779): Tests on a real 3DS shows that no error is returned in this case
    // and encrypted data is actually returned, but the key used is unknown.
    ASSERT_MSG(key_type != 7 && key_type < 10, "Key type is invalid");

    if (key_type == 0x5) {
        HW::AES::SelectDlpNfcKeyYIndex(HW::AES::DlpNfcKeyY::Dlp);
    } else if (key_type == 0x9) {
        HW::AES::SelectDlpNfcKeyYIndex(HW::AES::DlpNfcKeyY::Nfc);
    }

    if (!HW::AES::IsNormalKeyAvailable(KeyTypes[key_type])) {
        LOG_ERROR(Service_PS,
                  "Key 0x{:2X} is not available, encryption/decryption will not be correct",
                  KeyTypes[key_type]);
    }

    HW::AES::AESKey key = HW::AES::GetNormalKey(KeyTypes[key_type]);

    if (algorithm == AlgorithmType::CCM_Encrypt || algorithm == AlgorithmType::CCM_Decrypt) {
        // AES-CCM is not supported with this function
        IPC::RequestBuilder rb = rp.MakeBuilder(1, 4);
        rb.Push(ResultCode(ErrorDescription::InvalidSection, ErrorModule::PS,
                           ErrorSummary::WrongArgument, ErrorLevel::Status));
        rb.PushMappedBuffer(source);
        rb.PushMappedBuffer(destination);
        return;
    }

    if (algorithm == AlgorithmType::CBC_Encrypt || algorithm == AlgorithmType::CBC_Decrypt) {
        src_size &= 0xFFFFFFF0; // Clear the lowest 4 bits of the size (make it a multiple of 16)
        ASSERT(src_size > 0);   // Real 3DS calls svcBreak in this case
    }

    std::vector<u8> src_buffer(src_size);
    source.Read(src_buffer.data(), 0, src_buffer.size());

    std::vector<u8> dst_buffer(src_buffer.size());
    switch (algorithm) {
    case AlgorithmType::CTR_Encrypt: {
        CryptoPP::CTR_Mode<AES>::Encryption aes;
        aes.SetKeyWithIV(key.data(), AES::BLOCKSIZE, iv.data());
        aes.ProcessData(dst_buffer.data(), src_buffer.data(), src_buffer.size());
        break;
    }

    case AlgorithmType::CTR_Decrypt: {
        CryptoPP::CTR_Mode<AES>::Decryption aes;
        aes.SetKeyWithIV(key.data(), AES::BLOCKSIZE, iv.data());
        aes.ProcessData(dst_buffer.data(), src_buffer.data(), src_buffer.size());
        break;
    }

    case AlgorithmType::CBC_Encrypt: {
        CryptoPP::CBC_Mode<AES>::Encryption aes;
        aes.SetKeyWithIV(key.data(), AES::BLOCKSIZE, iv.data());
        aes.ProcessData(dst_buffer.data(), src_buffer.data(), src_buffer.size());
        break;
    }

    case AlgorithmType::CBC_Decrypt: {
        CryptoPP::CBC_Mode<AES>::Decryption aes;
        aes.SetKeyWithIV(key.data(), AES::BLOCKSIZE, iv.data());
        aes.ProcessData(dst_buffer.data(), src_buffer.data(), src_buffer.size());
        break;
    }

    default:
        UNREACHABLE();
    }

    destination.Write(dst_buffer.data(), 0, dst_buffer.size());

    // We will need to calculate the resulting IV/CTR ourselves as CrytoPP does not
    // provide an easy way to get them
    std::array<u8, AES::BLOCKSIZE> new_iv;
    if (algorithm == AlgorithmType::CTR_Encrypt || algorithm == AlgorithmType::CTR_Decrypt) {
        new_iv = HW::AES::Add128(iv, src_size / 16);
    } else if (algorithm == AlgorithmType::CBC_Encrypt) {
        // For AES-CBC, The new IV is the last block of ciphertext
        std::copy_n(dst_buffer.end() - new_iv.size(), new_iv.size(), new_iv.begin());
    } else {
        std::copy_n(src_buffer.end() - new_iv.size(), new_iv.size(), new_iv.begin());
    }

    IPC::RequestBuilder rb = rp.MakeBuilder(5, 4);
    rb.Push(RESULT_SUCCESS);
    rb.PushRaw(new_iv);
    rb.PushMappedBuffer(source);
    rb.PushMappedBuffer(destination);
}

PS_PS::PS_PS() : ServiceFramework("ps:ps", DefaultMaxSessions) {
    static const FunctionInfo functions[] = {
        // clang-format off
        {IPC::MakeHeader(0x0001, 9, 4), nullptr, "SignRsaSha256"},
        {IPC::MakeHeader(0x0002, 9, 4), nullptr, "VerifyRsaSha256"},
        {IPC::MakeHeader(0x0004, 8, 4), &PS_PS::EncryptDecryptAes, "EncryptDecryptAes"},
        {IPC::MakeHeader(0x0005, 10, 4), nullptr, "EncryptSignDecryptVerifyAesCcm"},
        {IPC::MakeHeader(0x0006, 1, 0), nullptr, "GetRomId"},
        {IPC::MakeHeader(0x0007, 1, 0), nullptr, "GetRomId2"},
        {IPC::MakeHeader(0x0008, 1, 0), nullptr, "GetRomMakerCode"},
        {IPC::MakeHeader(0x0009, 0, 0), nullptr, "GetCTRCardAutoStartupBit"},
        {IPC::MakeHeader(0x000A, 0, 0), nullptr, "GetLocalFriendCodeSeed"},
        {IPC::MakeHeader(0x000B, 0, 0), nullptr, "GetDeviceId"},
        {IPC::MakeHeader(0x000C, 0, 0), nullptr, "SeedRNG"},
        {IPC::MakeHeader(0x000D, 1, 2), nullptr, "GenerateRandomBytes"},
        {IPC::MakeHeader(0x000E, 2, 2), nullptr, "InterfaceForPXI_0x04010084"},
        {IPC::MakeHeader(0x000F, 2, 2), nullptr, "InterfaceForPXI_0x04020082"},
        {IPC::MakeHeader(0x0010, 1, 2), nullptr, "InterfaceForPXI_0x04030044"},
        {IPC::MakeHeader(0x0011, 1, 2), nullptr, "InterfaceForPXI_0x04040044"},
        // clang-format on
    };

    RegisterHandlers(functions);
};

void InstallInterfaces(Core::System& system) {
    auto& service_manager = system.ServiceManager();
    std::make_shared<PS_PS>()->InstallAsService(service_manager);
}

} // namespace Service::PS
