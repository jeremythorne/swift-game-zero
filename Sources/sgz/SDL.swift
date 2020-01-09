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
        if SDL_Init(SDL_INIT_VIDEO) < 0 {
            throw SDLError.error(message:"couldn't init " + getError())
        }
    }

    func createWindow(width:Int, height:Int) throws -> Window {
        return try Window(width:width, height:height)
    }

    func pollEvent() -> Event? {
        var sdl_event = SDL_Event()
        if SDL_PollEvent(&sdl_event) == 0 {
            return nil
        }
        return Event(sdl_event:sdl_event)
    }

    deinit {
        SDL_Quit()
    }
}

class Window {
    var window:OpaquePointer?
    init(width:Int, height:Int) throws {
        self.window = SDL_CreateWindow("hello",
                                       0,//SDL_WINDOWPOS_UNDEFINED,
                                       0,//SDL_WINDOWPOS_UNDEFINED,
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
            let texture = SDL_CreateTexture(self.renderer, UInt32(SDL_PIXELFORMAT_ABGR8888),
                                            Int32(SDL_TEXTUREACCESS_STATIC.rawValue),
                                            Int32(png.width),
                                            Int32(png.height))
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
