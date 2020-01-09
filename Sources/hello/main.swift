import sgz

class Ball:sgz.Actor {
    var v = (x:Float.random(in: -3.0...3.0),
             y:Float.random(in: -3.0...3.0))

    func update(app:sgz.App) {
        self.x += self.v.x
        self.y += self.v.y
        if self.x > app.width || self.x < 0 {
            self.v.x = -self.v.x
        }

        if self.y > app.height || self.y < 0 {
            self.v.y = -self.v.y
        }
    }
}

var balls = [Ball]()
class MyGame : sgz.Game {

    override func setup(app:App) {
        for _ in 1...10 {
            balls.append(Ball(image:"hello", center:(app.width / 2, app.height / 2)))
        }
    }

    override func update(app:sgz.App) {
        if app.pressed(sgz.KeyCode.left) {
            print("left pressed")
        } else if app.pressed(sgz.KeyCode.right) {
            print("right pressed")
        }

        for ball in balls {
            ball.update(app:app)
        }
    }

    override func draw(app:sgz.App) {
        app.clear()
        for ball in balls {
            ball.draw(app:app)
        }
    }
}

print("Hello, world!")

sgz.run(width:640, height:480, game:MyGame())
