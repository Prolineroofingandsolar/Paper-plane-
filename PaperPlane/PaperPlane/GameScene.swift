import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    weak var gameState: GameState?

    private var plane: SKNode!

    private let planeCat: UInt32 = 0x1 << 0
    private let wallCat: UInt32  = 0x1 << 1
    private let scoreCat: UInt32 = 0x1 << 2

    // Layout
    private let sideWallW: CGFloat = 28
    private let gapWidth: CGFloat  = 150
    private var scrollSpeed: CGFloat = 200

    // State
    private var isRunning = false
    private var lastUpdate: TimeInterval = 0
    private var spawnTimer: TimeInterval = 0
    private var spawnInterval: TimeInterval = 1.8

    // Plane movement — tap left half → go left, tap right half → go right
    private var planeVelocityX: CGFloat = 0
    private let tapImpulse: CGFloat = 320
    private let drag: CGFloat = 5.0

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.16, green: 0.10, blue: 0.08, alpha: 1)
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        drawBrickWalls()
        setupPlane()
    }

    // MARK: - Brick walls (static left/right strips)

    private func drawBrickWalls() {
        for side: CGFloat in [sideWallW / 2, size.width - sideWallW / 2] {
            let wall = SKSpriteNode(color: UIColor(red: 0.42, green: 0.24, blue: 0.14, alpha: 1),
                                   size: CGSize(width: sideWallW, height: size.height))
            wall.position = CGPoint(x: side, y: size.height / 2)
            wall.zPosition = 2

            let pb = SKPhysicsBody(rectangleOf: wall.size)
            pb.isDynamic = false
            pb.categoryBitMask = wallCat
            pb.contactTestBitMask = planeCat
            wall.physicsBody = pb
            addChild(wall)

            // Brick lines
            let brickH: CGFloat = 18
            let rows = Int(size.height / brickH) + 2
            for row in 0..<rows {
                let line = SKShapeNode(rectOf: CGSize(width: sideWallW, height: 1.5))
                line.fillColor = UIColor(red: 0.22, green: 0.10, blue: 0.06, alpha: 0.8)
                line.strokeColor = .clear
                line.position = CGPoint(x: side, y: CGFloat(row) * brickH)
                line.zPosition = 3
                addChild(line)
            }
        }
    }

    // MARK: - Plane

    private func setupPlane() {
        plane = SKNode()
        plane.position = CGPoint(x: size.width / 2, y: size.height * 0.72)
        plane.zPosition = 20

        // Body
        let bodyShape = SKShapeNode()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 18))      // nose points UP (plane falls down)
        path.addLine(to: CGPoint(x: -10, y: -14))
        path.addLine(to: CGPoint(x: 0, y: -8))
        path.addLine(to: CGPoint(x: 10, y: -14))
        path.close()
        bodyShape.path = path.cgPath
        bodyShape.fillColor = .white
        bodyShape.strokeColor = UIColor(white: 0.55, alpha: 1)
        bodyShape.lineWidth = 1.5

        // Wing
        let wingShape = SKShapeNode()
        let wp = UIBezierPath()
        wp.move(to: CGPoint(x: 0, y: 2))
        wp.addLine(to: CGPoint(x: -18, y: -4))
        wp.addLine(to: CGPoint(x: -6, y: -6))
        wp.close()
        wingShape.path = wp.cgPath
        wingShape.fillColor = UIColor(white: 0.88, alpha: 1)
        wingShape.strokeColor = UIColor(white: 0.5, alpha: 1)
        wingShape.lineWidth = 1

        plane.addChild(wingShape)
        plane.addChild(bodyShape)

        let pb = SKPhysicsBody(rectangleOf: CGSize(width: 18, height: 28))
        pb.isDynamic = true
        pb.affectedByGravity = false
        pb.categoryBitMask = planeCat
        pb.contactTestBitMask = wallCat | scoreCat
        pb.collisionBitMask = 0
        pb.allowsRotation = false
        plane.physicsBody = pb

        addChild(plane)
    }

    // MARK: - Platform spawning

    private func spawnPlatform() {
        // Gap randomly positioned between left and right bias
        let playableLeft  = sideWallW + 10
        let playableRight = size.width - sideWallW - 10
        let minGapCenter  = playableLeft + gapWidth / 2
        let maxGapCenter  = playableRight - gapWidth / 2
        let gapCenterX    = CGFloat.random(in: minGapCenter...maxGapCenter)

        let h: CGFloat = 22
        let node = SKNode()
        node.position = CGPoint(x: 0, y: -h)
        node.zPosition = 5

        // Left slab
        let leftW = gapCenterX - gapWidth / 2 - sideWallW
        if leftW > 4 {
            let s = makeSlab(width: leftW, height: h)
            s.position = CGPoint(x: sideWallW + leftW / 2, y: 0)
            node.addChild(s)
        }

        // Right slab
        let gapEnd  = gapCenterX + gapWidth / 2
        let rightW  = size.width - sideWallW - gapEnd
        if rightW > 4 {
            let s = makeSlab(width: rightW, height: h)
            s.position = CGPoint(x: gapEnd + rightW / 2, y: 0)
            node.addChild(s)
        }

        // Score sensor
        let sensor = SKNode()
        sensor.position = CGPoint(x: gapCenterX, y: h + 4)
        let sb = SKPhysicsBody(rectangleOf: CGSize(width: gapWidth - 16, height: 6))
        sb.isDynamic = false
        sb.categoryBitMask = scoreCat
        sb.contactTestBitMask = planeCat
        sb.collisionBitMask = 0
        sensor.physicsBody = sb
        node.addChild(sensor)

        addChild(node)

        let dist = size.height + h + 20
        let dur  = TimeInterval(dist / scrollSpeed)
        node.run(SKAction.sequence([
            SKAction.moveBy(x: 0, y: dist, duration: dur),
            SKAction.removeFromParent()
        ]))
    }

    private func makeSlab(width: CGFloat, height: CGFloat) -> SKNode {
        let node = SKNode()

        let shape = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 2)
        shape.fillColor = UIColor(white: 0.76, alpha: 1)
        shape.strokeColor = UIColor(white: 0.45, alpha: 1)
        shape.lineWidth = 1.5
        node.addChild(shape)

        // Brick joints
        var bx = -width / 2 + 26
        while bx < width / 2 - 4 {
            let v = SKShapeNode(rectOf: CGSize(width: 1.2, height: height - 5))
            v.fillColor = UIColor(white: 0.5, alpha: 0.5)
            v.strokeColor = .clear
            v.position = CGPoint(x: bx, y: 0)
            node.addChild(v)
            bx += 26
        }

        let pb = SKPhysicsBody(rectangleOf: CGSize(width: width, height: height))
        pb.isDynamic = false
        pb.categoryBitMask = wallCat
        pb.contactTestBitMask = planeCat
        node.physicsBody = pb

        return node
    }

    // MARK: - Update

    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdate == 0 ? 0 : min(currentTime - lastUpdate, 0.05)
        lastUpdate = currentTime
        guard isRunning else { return }

        scrollSpeed   = min(scrollSpeed + CGFloat(dt) * 6, 450)
        spawnInterval = max(0.9, spawnInterval - dt * 0.005)

        spawnTimer += dt
        if spawnTimer >= spawnInterval {
            spawnTimer = 0
            spawnPlatform()
        }

        // Apply drag to horizontal velocity
        planeVelocityX *= pow(1 - drag * CGFloat(dt), 1)

        // Move plane
        var newX = plane.position.x + planeVelocityX * CGFloat(dt)
        newX = max(sideWallW + 16, min(size.width - sideWallW - 16, newX))
        plane.position.x = newX

        // Tilt based on direction
        let tilt = max(-0.55, min(0.55, planeVelocityX / tapImpulse * 0.55))
        plane.zRotation += ((-tilt) - plane.zRotation) * 0.2
    }

    // MARK: - Contact

    func didBegin(_ contact: SKPhysicsContact) {
        let masks = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        if masks == planeCat | scoreCat {
            DispatchQueue.main.async { self.gameState?.addPoint() }
            (contact.bodyA.categoryBitMask == scoreCat ? contact.bodyA : contact.bodyB).node?.physicsBody = nil
        } else if masks == planeCat | wallCat {
            if isRunning { endGame() }
        }
    }

    // MARK: - Touch  (tap left half → impulse left, tap right half → impulse right)

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        if !isRunning && !(gameState?.isGameOver ?? false) {
            startGame()
            return
        }

        let tapX = touch.location(in: self).x
        planeVelocityX = tapX < size.width / 2 ? -tapImpulse : tapImpulse
    }

    // MARK: - Flow

    private func startGame() {
        isRunning    = true
        spawnTimer   = spawnInterval   // first platform immediately
        scrollSpeed  = 200
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
