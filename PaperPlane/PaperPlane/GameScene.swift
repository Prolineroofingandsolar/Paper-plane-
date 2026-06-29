import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    weak var gameState: GameState?

    private var plane: SKNode!
    private var leftWall: SKSpriteNode!
    private var rightWall: SKSpriteNode!

    private let planeCat: UInt32  = 0x1 << 0
    private let wallCat: UInt32   = 0x1 << 1
    private let scoreCat: UInt32  = 0x1 << 2

    private let wallW: CGFloat    = 32
    private let gapWidth: CGFloat = 140
    private var scrollSpeed: CGFloat = 180

    private var isRunning  = false
    private var touchX: CGFloat? = nil
    private var lastUpdate: TimeInterval = 0
    private var spawnTimer: TimeInterval = 0
    private var spawnInterval: TimeInterval = 2.0

    // MARK: - Setup

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.18, green: 0.12, blue: 0.10, alpha: 1)
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        buildSideWalls()
        buildBrickPattern()
        setupPlane()
    }

    private func buildSideWalls() {
        // Left wall strip
        leftWall = SKSpriteNode(color: UIColor(red: 0.45, green: 0.25, blue: 0.15, alpha: 1),
                                size: CGSize(width: wallW, height: size.height))
        leftWall.position = CGPoint(x: wallW / 2, y: size.height / 2)
        leftWall.zPosition = 2
        let lb = SKPhysicsBody(rectangleOf: leftWall.size)
        lb.isDynamic = false; lb.categoryBitMask = wallCat; lb.contactTestBitMask = planeCat
        leftWall.physicsBody = lb
        addChild(leftWall)

        // Right wall strip
        rightWall = SKSpriteNode(color: UIColor(red: 0.45, green: 0.25, blue: 0.15, alpha: 1),
                                 size: CGSize(width: wallW, height: size.height))
        rightWall.position = CGPoint(x: size.width - wallW / 2, y: size.height / 2)
        rightWall.zPosition = 2
        let rb = SKPhysicsBody(rectangleOf: rightWall.size)
        rb.isDynamic = false; rb.categoryBitMask = wallCat; rb.contactTestBitMask = planeCat
        rightWall.physicsBody = rb
        addChild(rightWall)
    }

    private func buildBrickPattern() {
        let brickH: CGFloat = 20
        let brickW: CGFloat = wallW - 2
        let rows = Int(size.height / brickH) + 2
        for row in 0..<rows {
            for side in [wallW / 2, size.width - wallW / 2] {
                let brick = SKShapeNode(rectOf: CGSize(width: brickW - 2, height: brickH - 3),
                                       cornerRadius: 1)
                brick.fillColor = UIColor(red: 0.50, green: 0.28, blue: 0.16, alpha: 1)
                brick.strokeColor = UIColor(red: 0.20, green: 0.10, blue: 0.06, alpha: 1)
                brick.lineWidth = 1
                brick.position = CGPoint(x: side, y: CGFloat(row) * brickH + brickH / 2)
                brick.zPosition = 3
                addChild(brick)
            }
        }
    }

    private func setupPlane() {
        plane = SKNode()
        plane.position = CGPoint(x: size.width / 2, y: size.height * 0.70)
        plane.zPosition = 20

        let body = SKShapeNode()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 22, y: 0))
        path.addLine(to: CGPoint(x: -22, y: 9))
        path.addLine(to: CGPoint(x: -14, y: 0))
        path.addLine(to: CGPoint(x: -22, y: -8))
        path.close()
        body.path = path.cgPath
        body.fillColor = .white
        body.strokeColor = UIColor(white: 0.6, alpha: 1)
        body.lineWidth = 1.5

        let wing = SKShapeNode()
        let wp = UIBezierPath()
        wp.move(to: CGPoint(x: 4, y: 0))
        wp.addLine(to: CGPoint(x: -8, y: 18))
        wp.addLine(to: CGPoint(x: -18, y: 3))
        wp.close()
        wing.path = wp.cgPath
        wing.fillColor = UIColor(white: 0.85, alpha: 1)
        wing.strokeColor = UIColor(white: 0.5, alpha: 1)
        wing.lineWidth = 1

        plane.addChild(wing)
        plane.addChild(body)

        let pb = SKPhysicsBody(rectangleOf: CGSize(width: 36, height: 16))
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
        let playableW = size.width - wallW * 2
        let minGapX = wallW + gapWidth / 2 + 10
        let maxGapX = size.width - wallW - gapWidth / 2 - 10
        let gapCenterX = CGFloat.random(in: minGapX...maxGapX)

        let platformNode = SKNode()
        platformNode.position = CGPoint(x: 0, y: -20)
        platformNode.zPosition = 5

        let platformH: CGFloat = 20

        // Left block (from left wall edge to gap start)
        let leftW = gapCenterX - gapWidth / 2 - wallW
        if leftW > 0 {
            let seg = makePlatformSegment(width: leftW, height: platformH)
            seg.position = CGPoint(x: wallW + leftW / 2, y: 0)
            platformNode.addChild(seg)
        }

        // Right block (from gap end to right wall edge)
        let gapEnd = gapCenterX + gapWidth / 2
        let rightW = size.width - wallW - gapEnd
        if rightW > 0 {
            let seg = makePlatformSegment(width: rightW, height: platformH)
            seg.position = CGPoint(x: gapEnd + rightW / 2, y: 0)
            platformNode.addChild(seg)
        }

        // Score sensor in the gap
        let sensor = SKNode()
        sensor.position = CGPoint(x: gapCenterX, y: platformH)
        let sb = SKPhysicsBody(rectangleOf: CGSize(width: gapWidth - 20, height: 8))
        sb.isDynamic = false
        sb.categoryBitMask = scoreCat
        sb.contactTestBitMask = planeCat
        sb.collisionBitMask = 0
        sensor.physicsBody = sb
        platformNode.addChild(sensor)

        addChild(platformNode)

        // Move upward and remove when off screen
        let distance = size.height + 60
        let duration = TimeInterval(distance / scrollSpeed)
        platformNode.run(SKAction.sequence([
            SKAction.moveBy(x: 0, y: distance, duration: duration),
            SKAction.removeFromParent()
        ]))
    }

    private func makePlatformSegment(width: CGFloat, height: CGFloat) -> SKNode {
        let node = SKNode()

        let shape = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 2)
        shape.fillColor = UIColor(white: 0.78, alpha: 1)
        shape.strokeColor = UIColor(white: 0.5, alpha: 1)
        shape.lineWidth = 1.5
        node.addChild(shape)

        // Brick texture lines on platform
        let lines = SKNode()
        let numBricks = Int(width / 28)
        for i in 0..<numBricks {
            let x = -width / 2 + CGFloat(i) * (width / CGFloat(max(numBricks, 1)))
            let vl = SKShapeNode(rectOf: CGSize(width: 1, height: height - 4))
            vl.fillColor = UIColor(white: 0.55, alpha: 0.6)
            vl.strokeColor = .clear
            vl.position = CGPoint(x: x, y: 0)
            lines.addChild(vl)
        }
        node.addChild(lines)

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

        // Ramp up speed
        scrollSpeed = min(scrollSpeed + CGFloat(dt) * 5, 400)
        spawnInterval = max(1.0, spawnInterval - dt * 0.01)

        // Spawn timer
        spawnTimer += dt
        if spawnTimer >= spawnInterval {
            spawnTimer = 0
            spawnPlatform()
        }

        // Steer plane toward touch
        if let tx = touchX {
            let cx = plane.position.x
            let newX = cx + (tx - cx) * min(CGFloat(dt) * 10, 1)
            plane.position.x = max(wallW + 20, min(size.width - wallW - 20, newX))
            let dx = tx - cx
            plane.zRotation = CGFloat(atan2(Double(dx * 0.3), 60))
        } else {
            plane.zRotation *= 0.85
        }
    }

    // MARK: - Contact

    func didBegin(_ contact: SKPhysicsContact) {
        let masks = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        if masks == planeCat | scoreCat {
            DispatchQueue.main.async { self.gameState?.addPoint() }
            if contact.bodyA.categoryBitMask == scoreCat {
                contact.bodyA.node?.physicsBody = nil
            } else {
                contact.bodyB.node?.physicsBody = nil
            }
        } else if masks == planeCat | wallCat {
            if isRunning { endGame() }
        }
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchX = touches.first?.location(in: self).x
        if !isRunning && !(gameState?.isGameOver ?? false) {
            startGame()
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchX = touches.first?.location(in: self).x
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { touchX = nil }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { touchX = nil }

    // MARK: - Flow

    private func startGame() {
        isRunning = true
        spawnTimer = spawnInterval  // spawn first platform immediately
        DispatchQueue.main.async { self.gameState?.hasStarted = true }
    }

    private func endGame() {
        guard isRunning else { return }
        isRunning = false
        touchX = nil

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
