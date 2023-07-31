//
//  Bruno.swift
//  emuThreeDS
//
//  Created by Antique on 25/5/2023.
//

//
//  Bruno.swift
//  Bruno
//
//  Created by Emil Wojtaszek on 03/04/2018.
//  Copyright © 2018 AppUnite.com. All rights reserved.
//

import Accelerate
import UIKit

public protocol Bufferable {
    var buffer: vImage_Buffer { get }
    var height: Int { get }
    var width: Int { get }
    var rowBytes: Int { get }
}

public class RawBuffer: Bufferable {
    public private(set) var bytes: Data

    // dimensions
    public let width: Int
    public let height: Int
    public let rowBytes: Int

    public init(data: Data, width: Int, height: Int, rowBytes: Int) {
        self.bytes = data
        self.width = width
        self.height = height
        self.rowBytes = rowBytes
    }

    public var buffer: vImage_Buffer {
        // get bytes pointer
        let ptr = bytes.withUnsafeBytes {
            return UnsafeMutablePointer<UInt8>.init(mutating: $0)
        }

        return vImage_Buffer(data: ptr, height: vImagePixelCount(height), width: vImagePixelCount(width), rowBytes: rowBytes)
    }
}

public struct Bruno {
    public static func decode(srcBuffer: Bufferable) -> Bufferable? {
        let width = srcBuffer.width
        let height = srcBuffer.height

        // create empty data with proper count of bytes
        let rowBytes = width * 3
        let dstData = Data(count: height * rowBytes)
        let dstBuffer = RawBuffer(data: dstData, width: width, height: height, rowBytes: rowBytes)

        // mutate buffer
        var buffer565 = srcBuffer.buffer
        var buffer888 = dstBuffer.buffer

        // convert
        let error = vImageConvert_RGB565toRGB888(&buffer565, &buffer888, vImage_Flags(kvImageNoFlags))
        guard error == kvImageNoError else { return nil }

        //
        return dstBuffer
    }

    public static func encode(srcBuffer: Bufferable) -> Bufferable? {
        let width = srcBuffer.width
        let height = srcBuffer.height

        // create empty data with proper count of bytes
        let rowBytes = width * 2
        let dstData = Data(count: height * rowBytes)
        let dstBuffer = RawBuffer(data: dstData, width: width, height: height, rowBytes: rowBytes)

        // mutate buffer
        var buffer565 = dstBuffer.buffer
        var buffer8888 = srcBuffer.buffer

        // convert
        let error = vImageConvert_RGBA8888toRGB565(&buffer8888, &buffer565, vImage_Flags(kvImageNoFlags))
        guard error == kvImageNoError else { return nil }

        //
        return dstBuffer
    }
}

extension UIImage {
    public func encodeRGB565(width: Int, height: Int) -> Data? {
        // resize image and create source buffer
        guard let srcBytes = self.buffer(width: width, height: height)
            else { return nil }

        // encode
        guard let dstBuffer = Bruno.encode(srcBuffer: srcBytes)
            else { return nil }

        // get data
        return Data(bytes: dstBuffer.buffer.data, count: dstBuffer.buffer.rowBytes * Int(dstBuffer.buffer.height))
    }
}

extension Data {
    public func decodeRGB565(width: Int, height: Int) -> UIImage? {
        // create source buffer
        let srcBuffer = RawBuffer(data: self, width: width, height: height, rowBytes: width * 2)

        // decode
        guard let dstBuffer = Bruno.decode(srcBuffer: srcBuffer)
            else { return nil }

        //
        var format = vImage_CGImageFormat(bitsPerComponent: 8, bitsPerPixel: 24, colorSpace: nil, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue), version: 0, decode: nil, renderingIntent: .defaultIntent)

        //
        var buffer888 = dstBuffer.buffer
        var error: vImage_Error = 0
        let vImage = vImageCreateCGImageFromBuffer(&buffer888, &format, nil, nil, vImage_Flags(kvImageNoFlags), &error)
        guard error == kvImageNoError else { return nil }

        // create an UIImage
        return vImage.flatMap {
            UIImage(cgImage: $0.takeRetainedValue(), scale: 1.0, orientation: .up)
        }
    }
}

internal extension UIImage {
    func buffer(width: Int, height: Int) -> RawBuffer? {
        guard let cgImage = self.cgImage
            else { return nil }

        // bytes array
        let rowBytes = 4 * width
        var bytes = Array<UInt8>.init(repeating: 0, count: rowBytes * height)

        // create context for image
        guard let context = CGContext(data: &bytes, width: width, height: height, bitsPerComponent: 8, bytesPerRow: rowBytes, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
            else { return nil }

        // fill buffer
        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // create buffer
        let data = Data(buffer: UnsafeBufferPointer(start: &bytes, count: bytes.count))
        return RawBuffer(data: data, width: width, height: height, rowBytes: rowBytes)
    }
}
