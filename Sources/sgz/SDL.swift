import CSDL

func getError() ->String {
    if let u = SDL_GetError() {
        let string = String(cString: u)
        return string
    }
    return ""
}


enum SDLError: Error {
	case error(message:String)
}

class SDL {
    init() throws {
        if SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) < 0 {
            throw SDLError.error(message:"couldn't init " + getError())
        }
    }

    func createWindow(width:Int, height:Int) throws -> Window {
        return try Window(width:width, height:height)
    }

    func createAudio() throws -> Audio {
        let audio = Audio()
        try audio.start()
        return audio
    }

    func pollEvent() -> Event? {
        var sdl_event = SDL_Event()
        if SDL_PollEvent(&sdl_event) == 0 {
            return nil
        }
        return Event(sdl_event:sdl_event)
    }

    func time() -> Uint32 {
        return SDL_GetTicks()
    }

    func sleep(ms: Uint32) {
        SDL_Delay(ms)
    }

    deinit {
        SDL_Quit()
    }
}

func bridge<T : AnyObject>(obj : T) -> UnsafeMutableRawPointer {
    return UnsafeMutableRawPointer(Unmanaged.passUnretained(obj).toOpaque())
}

func bridge<T : AnyObject>(ptr : UnsafeMutableRawPointer) -> T {
    return Unmanaged<T>.fromOpaque(ptr).takeUnretainedValue()
}

func audioCallback(_ userdata_o: UnsafeMutableRawPointer?, _ stream_o:UnsafeMutablePointer<UInt8>?,_ len:Int32) {
    guard let userdata = userdata_o else {
        return
    }
    guard let stream = stream_o else {
        return
    }
    let audio:Audio = bridge(ptr:userdata)
    let count = Int(len) / MemoryLayout<Int16>.size

    stream.withMemoryRebound(to: Int16.self, capacity: count) {
        let buffer = UnsafeMutableBufferPointer(start:$0, count:count)
        for i in 0..<count {    
            buffer[i] = 0
            let offset = i + audio.offset
            if let sound = audio.sound {
                let sound_offset = offset - audio.sound_start
                if sound_offset < sound.samples.count {
                    buffer[i] += sound.samples[sound_offset]
                }
            }
        }
        audio.offset += count
    }
}

class Audio {
    var dev:SDL_AudioDeviceID = 0
    var have = SDL_AudioSpec()
    var sound:Sound?
    var sound_start = 0
    var offset = 0

    init() {
    }

    func start() throws {
        var want = SDL_AudioSpec()
        want.freq = 44100
        want.format = UInt16(AUDIO_S16LSB)
        want.channels = 2
        want.samples = 4096
        want.callback = audioCallback
        want.userdata = bridge(obj:self)
        self.dev = SDL_OpenAudioDevice(nil, 0, &want, &self.have, 0)
        guard self.dev != 0 else {
            throw SDLError.error(message: "couldn't open audio device")
        }
        SDL_PauseAudioDevice(self.dev, 0)
    }

    func loadSound(filename:String) -> Sound? {
        do {
            let v = try VorbisFile(filename:filename)
            return Sound(samples:v.samples)
        } catch VorbisFile.error.error(let message) {
            print("vorbis error:" + message)
        } catch {
            print("unknown error")
        }
        return nil
    }

    func play(sound:Sound) {
        SDL_LockAudioDevice(self.dev)
        self.sound = sound
        self.sound_start = self.offset
        SDL_UnlockAudioDevice(self.dev)
    }

    deinit {
        SDL_CloseAudioDevice(self.dev)
    }
}

class Window {
    var window:OpaquePointer?
    init(width:Int, height:Int) throws {
        self.window = SDL_CreateWindow("hello",
                                       0x2FFF0000,//SDL_WINDOWPOS_CENTERED,
                                       0x2FFF0000,//SDL_WINDOWPOS_CENTERED,
                                       Int32(width),
                                       Int32(height),
                                       0)
        if self.window == nil {
            throw SDLError.error(message: "couldn't create window")
        }
    }

    func createRenderer() throws -> Renderer {
        return try Renderer(window:self.window)
    }

    deinit {
        SDL_DestroyWindow(self.window)
    }
}

enum Event {
    case quit
    case other

    init(sdl_event:SDL_Event) {
        let type = SDL_EventType(sdl_event.type)
        switch type {
        case SDL_QUIT:
            self = .quit
        default:
            self = .other
        }
    }
}

class Texture {
    var width:Int
    var height:Int
    var texture:OpaquePointer
    init(width:Int, height:Int, texture:OpaquePointer) {
        self.width = width
        self.height = height
        self.texture = texture
    }
    deinit {
        SDL_DestroyTexture(self.texture)
    }
}

class Keyboard {
    let state:UnsafePointer<Uint8>
    var length:Int32 = 0
    init() {
        self.state = SDL_GetKeyboardState(&self.length)
    }

    func pressed(_ key:KeyCode) -> Bool {
        if key.rawValue < 0 || key.rawValue > self.length {
            return false
        }
        return state[key.rawValue] == 1
    }
}

class Renderer {
    var renderer:OpaquePointer?

    init(window:OpaquePointer?) throws {
        self.renderer = SDL_CreateRenderer(window, -1, 0)
        if self.renderer == nil {
            throw SDLError.error(message: "couldn't create renderer")
        }
    }

    func clear() {
        SDL_RenderClear(self.renderer)
    }

    func flip() {
        SDL_RenderPresent(self.renderer)
    }
    
    func loadImage(filename:String) -> Texture? {
        do {
            let png = try PNG(filename:filename)
#if os(Linux)
            let texture = SDL_CreateTexture(self.renderer, UInt32(SDL_PIXELFORMAT_ABGR8888),
                                            Int32(SDL_TEXTUREACCESS_STATIC.rawValue),
                                            Int32(png.width),
                                            Int32(png.height))
#else
// mac os
            let texture = SDL_CreateTexture(self.renderer, UInt32(SDL_PIXELFORMAT_ABGR8888.rawValue),
                                            Int32(SDL_TEXTUREACCESS_STATIC.rawValue),
                                            Int32(png.width),
                                            Int32(png.height))
#endif
            if texture == nil {
                print("failed to create texture")
                return nil
            }
            var rect = SDL_Rect()
            rect.x = 0
            rect.y = 0
            rect.w = Int32(png.width)
            rect.h = Int32(png.height)
            if (SDL_UpdateTexture(texture, &rect, png.bytes, Int32(png.width * 4)) != 0) {
                print("failed to set texture pixels")
                return nil
            }
            SDL_SetTextureBlendMode(texture, SDL_BLENDMODE_BLEND)
            return Texture(width:png.width, height:png.height, texture:texture!)
        } catch PNG.error.error(let message) {
            print ("error loading \(filename):", message)
        } catch {
            print ("unknown error")
	    }
        return nil
    }

    func blit(texture:Texture, pos:(x:Int, y:Int)) {
        var rect = SDL_Rect()
        rect.x = Int32(pos.x)
        rect.y = Int32(pos.y)
        rect.w = Int32(texture.width)
        rect.h = Int32(texture.height)
        SDL_RenderCopy(self.renderer, texture.texture, nil, &rect)
    }

    deinit {
        SDL_DestroyRenderer(self.renderer)
    }
}

public class Sound {
    var samples = [Int16]()
    init(samples:[Int16]) {
        self.samples = samples
    }
}
