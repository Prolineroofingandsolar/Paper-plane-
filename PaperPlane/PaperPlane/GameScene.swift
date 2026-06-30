import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    weak var gameState: GameState?
    var selectedSkin: PlaneSkin = PlaneSkin.all[0]

    private var plane: SKNode!

    private let planeCat: UInt32 = 0x1 << 0
    private let slabCat: UInt32  = 0x1 << 1
    private let scoreCat: UInt32 = 0x1 << 2

    // Layout
    private let sideWallW: CGFloat = 30

    // Flight physics
    private var planeAngle: CGFloat    = 0       // 0 = straight down, + = tilted right
    private let maxAngle: CGFloat      = 0.75    // ~43 degrees
    private let tapRotation: CGFloat   = 0.38    // radians per tap
    private let straightenRate: CGFloat = 1.3    // how fast angle returns to 0
    private let forwardSpeed: CGFloat  = 270     // pixels/sec along heading

    // Pitch (nose-up stall)
    private var pitchAngle: CGFloat      = 0
    private let maxPitch: CGFloat        = 0.55
    private let tapPitch: CGFloat        = 0.40
    private let pitchDecay: CGFloat      = 1.8

    // Scroll
    private var scrollSpeed: CGFloat     = 180
    private var effectiveScroll: CGFloat = 180

    // State
    private var isRunning  = false
    private var lastUpdate: TimeInterval = 0
    private var spawnTimer: TimeInterval = 0
    private var spawnInterval: TimeInterval = 1.2
    private var nextSideIsLeft: Bool = true

    // MARK: - Setup

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.15, green: 0.10, blue: 0.08, alpha: 1)
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        drawBrickWalls()
        setupPlane()
    }

    private func drawBrickWalls() {
        for (side, isLeft) in [(sideWallW / 2, true), (size.width - sideWallW / 2, false)] {
            // Wall background
            let wall = SKSpriteNode(
                color: UIColor(red: 0.40, green: 0.22, blue: 0.12, alpha: 1),
                size: CGSize(width: sideWallW, height: size.height))
            wall.position = CGPoint(x: side, y: size.height / 2)
            wall.zPosition = 2
            // No physics — side wall deflection is handled by position check in update()
            addChild(wall)

            // Brick mortar lines
            let brickH: CGFloat = 20
            var y: CGFloat = 0
            var row = 0
            while y < size.height {
                // Horizontal mortar
                let hLine = SKSpriteNode(color: UIColor(red: 0.18, green: 0.09, blue: 0.05, alpha: 1),
                                         size: CGSize(width: sideWallW, height: 1.5))
                hLine.position = CGPoint(x: side, y: y)
                hLine.zPosition = 3
                addChild(hLine)

                // Vertical joint (alternating offset)
                let jointOffset: CGFloat = (row % 2 == 0) ? 0 : sideWallW * 0.5
                let vLine = SKSpriteNode(color: UIColor(red: 0.18, green: 0.09, blue: 0.05, alpha: 1),
                                          size: CGSize(width: 1.5, height: brickH))
                vLine.position = CGPoint(x: isLeft ? sideWallW * 0.5 + jointOffset : side - sideWallW * 0.5 + jointOffset,
                                         y: y + brickH / 2)
                vLine.zPosition = 3
                addChild(vLine)

                y += brickH
                row += 1
            }
        }
    }

    private func setupPlane() {
        plane = SKNode()
        plane.position = CGPoint(x: size.width / 2, y: size.height * 0.68)
        plane.zPosition = 20

        // Plane points DOWNWARD — nose at bottom
        let bodyShape = SKShapeNode()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: -20))     // nose (bottom)
        path.addLine(to: CGPoint(x: -11, y: 14))  // left tail
        path.addLine(to: CGPoint(x: 0, y:  7))    // tail notch
        path.addLine(to: CGPoint(x: 11, y: 14))   // right tail
        path.close()
        bodyShape.path = path.cgPath
        bodyShape.fillColor = selectedSkin.bodyColor
        bodyShape.strokeColor = selectedSkin.strokeColor
        bodyShape.lineWidth = 1.5

        // Wing — left side
        let wingShape = SKShapeNode()
        let wp = UIBezierPath()
        wp.move(to: CGPoint(x: -1, y: 4))
        wp.addLine(to: CGPoint(x: -20, y: 2))
        wp.addLine(to: CGPoint(x: -8, y: -4))
        wp.close()
        wingShape.path = wp.cgPath
        wingShape.fillColor = selectedSkin.wingColor
        wingShape.strokeColor = selectedSkin.strokeColor
        wingShape.lineWidth = 1

        plane.addChild(wingShape)
        plane.addChild(bodyShape)

        let pb = SKPhysicsBody(rectangleOf: CGSize(width: 18, height: 30))
        pb.isDynamic = true
        pb.affectedByGravity = false
        pb.categoryBitMask = planeCat
        pb.contactTestBitMask = slabCat | scoreCat
        pb.collisionBitMask = 0
        pb.allowsRotation = false
        plane.physicsBody = pb

        addChild(plane)
    }

    // MARK: - Platform spawning

    private func spawnPlatform() {
        let playableW = size.width - sideWallW * 2
        let barCoverage = CGFloat.random(in: 0.52...0.65)
        let barW = playableW * barCoverage
        let openW = playableW - barW
        let h: CGFloat = 20

        let node = SKNode()
        node.position = CGPoint(x: 0, y: -h)
        node.zPosition = 5

        if nextSideIsLeft {
            // Bar from LEFT wall — open gap on the right
            let slab = makeSlab(width: barW, height: h)
            slab.position = CGPoint(x: sideWallW + barW / 2, y: 0)
            node.addChild(slab)

            let sensor = makeScoreSensor(width: openW, height: h)
            sensor.position = CGPoint(x: sideWallW + barW + openW / 2, y: h + 6)
            node.addChild(sensor)
        } else {
            // Bar from RIGHT wall — open gap on the left
            let slab = makeSlab(width: barW, height: h)
            slab.position = CGPoint(x: size.width - sideWallW - barW / 2, y: 0)
            node.addChild(slab)

            let sensor = makeScoreSensor(width: openW, height: h)
            sensor.position = CGPoint(x: sideWallW + openW / 2, y: h + 6)
            node.addChild(sensor)
        }
        nextSideIsLeft.toggle()

        addChild(node)

        let dist = size.height + h + 30
        let dur  = TimeInterval(dist / max(effectiveScroll, 60))
        node.run(SKAction.sequence([
            SKAction.moveBy(x: 0, y: dist, duration: dur),
            SKAction.removeFromParent()
        ]))
    }

    private func makeScoreSensor(width: CGFloat, height: CGFloat) -> SKNode {
        let sensor = SKNode()
        let sb = SKPhysicsBody(rectangleOf: CGSize(width: max(width - 10, 4), height: 8))
        sb.isDynamic = false
        sb.categoryBitMask = scoreCat
        sb.contactTestBitMask = planeCat
        sb.collisionBitMask = 0
        sensor.physicsBody = sb
        return sensor
    }

    private func makeSlab(width: CGFloat, height: CGFloat) -> SKNode {
        let node = SKNode()

        let shape = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 2)
        shape.fillColor = UIColor(white: 0.76, alpha: 1)
        shape.strokeColor = UIColor(white: 0.45, alpha: 1)
        shape.lineWidth = 1.5
        node.addChild(shape)

        // Brick joints
        var bx = -width / 2 + 28
        while bx < width / 2 - 4 {
            let v = SKShapeNode(rectOf: CGSize(width: 1.2, height: height - 6))
            v.fillColor = UIColor(white: 0.5, alpha: 0.5)
            v.strokeColor = .clear
            v.position = CGPoint(x: bx, y: 0)
            node.addChild(v)
            bx += 28
        }

        let pb = SKPhysicsBody(rectangleOf: CGSize(width: width, height: height))
        pb.isDynamic = false
        pb.categoryBitMask = slabCat
        pb.contactTestBitMask = planeCat
        node.physicsBody = pb

        return node
    }

    // MARK: - Update

    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdate == 0 ? 0 : min(currentTime - lastUpdate, 0.05)
        lastUpdate = currentTime
        guard isRunning else { return }

        // Ramp up
        scrollSpeed   = min(scrollSpeed + CGFloat(dt) * 5, 420)
        spawnInterval = max(0.6, spawnInterval - dt * 0.004)

        // Pitch decay — nose falls back to level naturally
        pitchAngle -= pitchAngle * pitchDecay * CGFloat(dt)

        // Effective scroll is reduced when nose is pitched up (stall)
        effectiveScroll = scrollSpeed * (1.0 - pitchAngle * 0.6)

        // Spawn
        spawnTimer += dt
        if spawnTimer >= spawnInterval {
            spawnTimer = 0
            spawnPlatform()
        }

        // Aerodynamic straightening — angle drifts back toward 0
        planeAngle -= planeAngle * straightenRate * CGFloat(dt)

        // Horizontal drift from angle
        let dx = sin(planeAngle) * forwardSpeed * CGFloat(dt)
        var newX = plane.position.x + dx
        newX = max(sideWallW + 16, min(size.width - sideWallW - 16, newX))

        // Side wall bounce — deflect angle back toward center (no death)
        if newX <= sideWallW + 16 && planeAngle < 0 {
            planeAngle = abs(planeAngle) * 0.25   // snap sharply toward right
            bounceEffect()
        } else if newX >= size.width - sideWallW - 16 && planeAngle > 0 {
            planeAngle = -abs(planeAngle) * 0.25  // snap sharply toward left
            bounceEffect()
        }

        plane.position.x = newX

        // Visual rotation — banking + nose-up pitch combined
        let targetRotation = -planeAngle + pitchAngle * 0.5
        plane.zRotation += (targetRotation - plane.zRotation) * 0.25
    }

    private func bounceEffect() {
        let bump = SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 0.06),
            SKAction.scale(to: 1.0,  duration: 0.06)
        ])
        plane.run(bump)
    }

    // MARK: - Contact

    func didBegin(_ contact: SKPhysicsContact) {
        let masks = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        if masks == planeCat | scoreCat {
            DispatchQueue.main.async { self.gameState?.addPoint() }
            (contact.bodyA.categoryBitMask == scoreCat ? contact.bodyA : contact.bodyB)
                .node?.physicsBody = nil
        } else if masks == planeCat | slabCat {
            if isRunning { endGame() }
        }
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        if !isRunning && !(gameState?.isGameOver ?? false) {
            startGame()
            return
        }

        guard isRunning else { return }
        let tapX = touch.location(in: self).x
        pitchAngle = min(maxPitch, pitchAngle + tapPitch)   // nose up on every tap
        if tapX < size.width / 2 {
            planeAngle = max(-maxAngle, planeAngle - tapRotation)   // bank left
        } else {
            planeAngle = min(maxAngle, planeAngle + tapRotation)    // bank right
        }
    }

    // MARK: - Flow

    private func startGame() {
        isRunning       = true
        spawnTimer      = spawnInterval   // trigger first platform immediately
        scrollSpeed     = 180
        effectiveScroll = 180
        planeAngle      = 0
        pitchAngle      = 0
        DispatchQueue.main.async { self.gameState?.hasStarted = true }
    }

    private func endGame() {
        guard isRunning else { return }
        isRunning = false

        let flash = SKAction.repeat(SKAction.sequence([
            SKAction.colorize(with: .red, colorBlendFactor: 1, duration: 0.07),
            SKAction.colorize(with: .white, colorBlendFactor: 0, duration: 0.07)
        ]), count: 4)
        plane.children.forEach { ($0 as? SKShapeNode)?.run(flash) }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.gameState?.triggerGameOver()
        }
    }

    override func willMove(from view: SKView) {
        removeAllChildren()
        removeAllActions()
    }
}
