open class Game {
    public init() {}

    open func setup (app:App) {
    }

    open func update (app:App) {
    }

    open func draw (app:App) {
    }
}

public enum Anchor {
    case top, bottom, left, right, middle, center
}

open class Actor {
    public var image:String = ""
    public var x:Float = 0
    public var y:Float = 0
    public var anchor:(x:Anchor, y:Anchor)

    public init(image:String, pos:(x:Float, y:Float),
                anchor:(x:Anchor, y:Anchor) = (Anchor.center, Anchor.center)) {
        self.image = image
        self.x = pos.x
        self.y = pos.y
        self.anchor = anchor
    }

    public func draw (app:App) {
        app.blit(name:self.image, pos:(self.x, self.y), anchor:self.anchor)
    }
}

public class Image {
    public var width:Int
    public var height:Int
    var texture:Texture

    init (width: Int, height: Int, texture: Texture) {
        self.width = width
        self.height = height
        self.texture = texture
    }
}

public func run(width:Int, height:Int, game:Game) {
    let app = App()
    app.run(width:width, height:height, game:game)
}

public class App {
    public var width:Float = 0.0
    public var height:Float = 0.0
    var sdl:SDL? = nil
    var keyboard:Keyboard? = nil
    var renderer:Renderer? = nil
    var audio:Audio? = nil
    var shouldQuit:Bool = false
    var imageCache = [String: Image]()
    var soundCache = [String: Sound]()

    public init() {
        do {
            self.sdl = try SDL()
            self.keyboard = Keyboard()
        } catch SDLError.error(let message) {
            print ("error:", message)
        }
        catch {
            print("unknown error")
        }
    }

    public func run(width:Int, height:Int, game:Game) {
        guard let sdl = self.sdl else {
            return
        }
        self.width = Float(width)
        self.height = Float(height)
        do {
            let window = try sdl.createWindow(width: width, height: height)
            self.renderer = try window.createRenderer()
            self.audio = try sdl.createAudio()
            self.shouldQuit = false

            setup(game)

            var time = sdl.time()
            while !self.shouldQuit {
                while let event = sdl.pollEvent() {
                    switch event {
                    case .quit:
                        self.shouldQuit = true
                    default:
                        continue
                    }
                }
                if pressed(KeyCode.escape) {
                    self.shouldQuit = true
                }
                if self.shouldQuit {
                    break
                }

                update(game)
                draw(game)

                let diff = sdl.time() - time
                if diff < 16 {
                    sdl.sleep(ms: 16 - diff)
                }
                time = sdl.time()
            }
        } catch SDLError.error(let message) {
            print ("error:", message)
        }
        catch {
            print("unknown error")
        }
    }

    func setup(_ game:Game) {
        game.setup(app:self)
    }

    func update(_ game:Game) {
        game.update(app:self)
    }

    func draw(_ game:Game) {
        guard let renderer = self.renderer else {
            return
        }
        game.draw(app:self)
        renderer.flip()
    }
    
    public func loadImage(name:String) -> Image? {
        let filename = "images/" + name + ".png"
        if let image = self.imageCache[name] {
            return image
        }
        guard let renderer = self.renderer else {
            print("no renderer")
            return nil
	    }
        guard let texture = renderer.loadImage(filename:filename) else {
            print("failed to load \(filename)")
            return nil
        }
        let image = Image(width:texture.width, height:texture.height, texture:texture)
        self.imageCache[name] = image
        return image
    }

    public func clear() {
        if let renderer = self.renderer {
            renderer.clear()
        }
    }

    func offset(anchor:Anchor, size:Float) -> Float {
        switch anchor {
        case Anchor.top, Anchor.left:
            return 0
        case Anchor.bottom, Anchor.right:
            return size
        case Anchor.middle, Anchor.center:
            return size / 2.0
        }
    }
    
    public func blit(name:String, pos:(x:Float, y:Float),
                    anchor:(x:Anchor, y:Anchor) = (Anchor.left, Anchor.top)) {
        if let image = self.loadImage(name:name) {
            let abs_pos = (pos.x - offset(anchor:anchor.x, size:Float(image.width)),
                           pos.y - offset(anchor:anchor.y, size:Float(image.height)))
            self.blit(image:image, pos:abs_pos)
        }
    }

    public func blit(image:Image?, pos:(x:Float, y:Float)) {
        guard let renderer = self.renderer else {
            return
        }
        guard let im = image else {
            return
        }
        renderer.blit(texture:im.texture, pos:(x:Int(pos.x), y:Int(pos.y)))
    }

    public func pressed(_ key:KeyCode) -> Bool {
        guard let keyboard = self.keyboard else {
            return false
        }
        return keyboard.pressed(key)
    }

    public func loadSound(name:String) -> Sound? {
        let filename = "sounds/" + name + ".ogg"
        if let sound = self.soundCache[name] {
            return sound
        }
        guard let audio = self.audio else {
            print("no audio")
            return nil
	    }
        guard let sound = audio.loadSound(filename:filename) else {
            print("failed to load \(filename)")
            return nil
        }
        self.soundCache[name] = sound
        return sound
    }

    public func playSound(name:String) {
        self.playSound(sound:self.loadSound(name:name))
    }

    public func playSound(sound:Sound?) {
        guard let s = sound else {
            return
        }
        guard let audio = self.audio else {
            return
        }
        audio.play(sound:s)
    }
}
