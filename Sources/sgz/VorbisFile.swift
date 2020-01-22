import CVorbisFile

class VorbisFile {
    var samples = [Int16]()
    enum error:Error {
        case error(message:String)
    }

    init(filename:String) throws {
        var vf = OggVorbis_File()
        var r:Int32 = 0
        filename.withCString {cs in r = ov_fopen(cs, &vf)}
        guard r >= 0 else {
            throw error.error(message:"\(filename) does not appear to be an Ogg file")
        }
        var bytes = [Int8]()
        bytes.reserveCapacity(4096)
        let p = UnsafeMutablePointer<Int8>(mutating:bytes)
        var eof = false
        var current_section:Int32 = 0
        while !eof {
            var ret = ov_read(&vf, p, 4096, 0, 2, 1, &current_section)
            if ret == 0 {
                eof = true
            } else if ret < 0 {
                print("stream error: \(ret)")
            } else {
                print("\(ret) bytes of valid data")
                let count:Int = ret / 2
                p.withMemoryRebound(to: Int16.self, capacity:count) {
                    self.samples += Array(UnsafeBufferPointer(start:$0, count:count))
                }
            }
        }
        print("done")
        defer {
            ov_clear(&vf)
        }
    }
}
