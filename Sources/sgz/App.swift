open class Game {
    public init() {}

    open func setup (app:App) {
    }

    open func update (app:App) {
    }

    open func draw (app:App) {
    }
}

open class Actor {
    public var image:String = ""
    public var x:Float = 0
    public var y:Float = 0

    public init(image:String, center:(x:Float, y:Float)) {
        self.image = image
        self.x = center.x
        self.y = center.y
    }

    public func draw (app:App) {
        app.blit(name:self.image, center:(self.x, self.y))
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
    var shouldQuit:Bool = false
    var imageCache = [String: Image]()

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

            self.shouldQuit = false

            setup(game)

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

    public func blit(name:String, pos:(x:Float, y:Float)) {
        self.blit(image:self.loadImage(name:name), pos:pos)
    }

    public func blit(name:String, center:(x:Float, y:Float)) {
        if let image = self.loadImage(name:name) {
            let pos = (center.x - Float(image.width) / 2.0,
                       center.y - Float(image.height) / 2.0)
            self.blit(image:image, pos:pos)
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
}
