# swift-game-zero
 pygame zero like environment written in swift on SDL - a simple way to get started with 2D games programming in swift on linux

written and tested on Raspberry Pi 3 and Mac OSX
## Getting Started

### Raspberry PI
* install swift
https://lickability.com/blog/swift-on-raspberry-pi/
* install SDL2 and libVorbis `apt install libsdl2-dev libvorbis-dev`
* bump up your swap size (otherwise your pi will grind to a halt while building) https://wpitchoune.net/tricks/raspberry_pi3_increase_swap_size.html
* clone this repository `git clone https://github.com/jeremythorne/swift-game-zero.git`
* build `swift build`
* run `.build/debug/hello`

### Mac OSX
* install XCode (just so that Swift Package Manager works properly from the command line)
* install homebrew https://brew.sh/
* use homebrew to install SDL2 and libVorbis `brew install sdl2 libvorbis`
* clone this repository `git clone https://github.com/jeremythorne/swift-game-zero.git`
* build `swift build -Xlinker -L/usr/local/lib/`
* run `.build/debug/hello`

## Example code
* see Sources/hello/main.swift
* more examples at https://github.com/jeremythorne/Code-the-Classics
