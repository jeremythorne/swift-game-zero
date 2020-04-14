import sgz

class Ball:sgz.Actor {
    var v = (x:Float.random(in: -3.0...3.0),
             y:Float.random(in: -3.0...3.0))

    func update(app:sgz.App) {
        x += v.x
        y += v.y
        if x > app.width || x < 0 {
            v.x = -v.x
        }

        if y > app.height || y < 0 {
            v.y = -v.y
        }
    }
}

var balls = [Ball]()
class MyGame : sgz.Game {

    override func setup(app:App) {
        for _ in 1...10 {
            balls.append(Ball(image:"hello", pos:(app.width / 2, app.height / 2)))
        }
    }

    override func update(app:sgz.App) {
        if app.pressed(sgz.KeyCode.left) {
            print("left pressed")
            app.playSound(name:"score_goal0")
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
