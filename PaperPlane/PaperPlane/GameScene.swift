import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    weak var gameState: GameState?

    // Nodes
    private var plane: SKNode!
    private var worldNode: SKNode!
    private var bgNode: SKNode!

    // Physics categories
    private let planeCat: UInt32  = 0x1 << 0
    private let wallCat: UInt32   = 0x1 << 1
    private let scoreCat: UInt32  = 0x1 << 2

    // Game config
    private let planeStartY: CGFloat = -100  // world coords (world scrolls down)
    private var scrollSpeed: CGFloat = 160   // pts/sec downward scroll
    private let platformGap: CGFloat = 130   // gap width the plane flies through
    private let platformSpacing: CGFloat = 260 // vertical distance between platforms
    private let brickSize: CGFloat = 24

    // State
    private var isRunning = false
    private var lastUpdate: TimeInterval = 0
    private var worldY: CGFloat = 0           // how far world has scrolled
    private var nextPlatformY: CGFloat = -500 // next platform spawn Y in world coords
    private var platformCount: Int = 0

    // Input
    private var touchX: CGFloat? = nil        // nil = no touch

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(white: 0.15, alpha: 1)
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        worldNode = SKNode()
        addChild(worldNode)

        bgNode = SKNode()
        addChild(bgNode)

        buildBrickWalls()
        setupPlane()
        spawnInitialPlatforms()
    }

    // MARK: - Background brick walls

    private func buildBrickWalls() {
        // Draw tiled brick texture on left/right side panels
        // We'll just render them procedurally as the world scrolls
    }

    private func makeBrickStrip(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) -> SKShapeNode {
        let strip = SKShapeNode(rectOf: CGSize(width: w, height: h))
        strip.fillColor = UIColor(red: 0.38, green: 0.22, blue: 0.15, alpha: 1)
        strip.strokeColor = .clear
        strip.position = CGPoint(x: x, y: y)
        strip.zPosition = 0

        // Brick lines overlay
        let lines = SKNode()
        let rows = Int(h / brickSize) + 1
        for row in 0...rows {
            let yOff = CGFloat(row) * brickSize - h / 2
            let hLine = SKShapeNode(rectOf: CGSize(width: w, height: 1.5))
            hLine.fillColor = UIColor(white: 0.1, alpha: 0.6)
            hLine.strokeColor = .clear
            hLine.position = CGPoint(x: 0, y: yOff)
            lines.addChild(hLine)

            // Alternating vertical joints
            let offset: CGFloat = (row % 2 == 0) ? 0 : brickSize * 1.5
            var xOff = -w / 2 + offset
            while xOff < w / 2 {
                let vLine = SKShapeNode(rectOf: CGSize(width: 1.5, height: brickSize))
                vLine.fillColor = UIColor(white: 0.1, alpha: 0.5)
                vLine.strokeColor = .clear
                vLine.position = CGPoint(x: xOff, y: yOff + brickSize / 2)
                lines.addChild(vLine)
                xOff += brickSize * 3
            }
        }
        strip.addChild(lines)
        return strip
    }

    // MARK: - Plane

    private func setupPlane() {
        plane = SKNode()
        plane.position = CGPoint(x: size.width / 2, y: size.height * 0.65)
        plane.zPosition = 20

        // Paper plane shape
        let body = SKShapeNode()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 20, y: 0))
        path.addLine(to: CGPoint(x: -20, y: 8))
        path.addLine(to: CGPoint(x: -12, y: 0))
        path.addLine(to: CGPoint(x: -20, y: -7))
        path.close()
        body.path = path.cgPath
        body.fillColor = .white
        body.strokeColor = UIColor(white: 0.6, alpha: 1)
        body.lineWidth = 1

        let wing = SKShapeNode()
        let wp = UIBezierPath()
        wp.move(to: CGPoint(x: 2, y: 0))
        wp.addLine(to: CGPoint(x: -10, y: 16))
        wp.addLine(to: CGPoint(x: -16, y: 2))
        wp.close()
        wing.path = wp.cgPath
        wing.fillColor = UIColor(white: 0.85, alpha: 1)
        wing.strokeColor = UIColor(white: 0.5, alpha: 1)
        wing.lineWidth = 1

        plane.addChild(wing)
        plane.addChild(body)

        let physBody = SKPhysicsBody(rectangleOf: CGSize(width: 32, height: 16))
        physBody.isDynamic = true
        physBody.affectedByGravity = false
        physBody.categoryBitMask = planeCat
        physBody.contactTestBitMask = wallCat | scoreCat
        physBody.collisionBitMask = 0
        physBody.allowsRotation = false
        plane.physicsBody = physBody

        addChild(plane)
    }

    // MARK: - Platforms

    private func spawnInitialPlatforms() {
        for i in 0..<8 {
            spawnPlatform(atWorldY: CGFloat(i) * -platformSpacing - 500)
        }
    }

    private func spawnPlatform(atWorldY wy: CGFloat) {
        let channelWidth: CGFloat = size.width * 0.55
        let wallW = (size.width - channelWidth) / 2

        // Randomly position the gap: left-biased, center, or right-biased
        let positions: [CGFloat] = [
            wallW / 2,                          // gap near left
            size.width / 2,                     // gap center
            size.width - wallW / 2              // gap near right
        ]
        let gapCenterX = positions[Int.random(in: 0..<positions.count)]

        let platformNode = SKNode()
        platformNode.position = CGPoint(x: 0, y: wy)
        platformNode.zPosition = 5

        let platformH: CGFloat = 18

        // Left wall panel
        let lw = gapCenterX - platformGap / 2
        if lw > 0 {
            let left = makeWallSegment(width: lw, height: platformH)
            left.position = CGPoint(x: lw / 2, y: 0)
            platformNode.addChild(left)
        }

        // Right wall panel
        let rStart = gapCenterX + platformGap / 2
        let rw = size.width - rStart
        if rw > 0 {
            let right = makeWallSegment(width: rw, height: platformH)
            right.position = CGPoint(x: rStart + rw / 2, y: 0)
            platformNode.addChild(right)
        }

        // Score sensor (invisible, in the gap)
        let sensor = SKNode()
        sensor.position = CGPoint(x: gapCenterX, y: 0)
        let sb = SKPhysicsBody(rectangleOf: CGSize(width: platformGap - 10, height: 10))
        sb.isDynamic = false
        sb.categoryBitMask = scoreCat
        sb.contactTestBitMask = planeCat
        sb.collisionBitMask = 0
        sensor.physicsBody = sb
        platformNode.addChild(sensor)

        worldNode.addChild(platformNode)
        nextPlatformY = wy - platformSpacing
        platformCount += 1

        // Brick walls on left and right edges
        let sideW: CGFloat = 30
        let brickH: CGFloat = platformSpacing + 40
        let leftBrick = makeBrickStrip(x: sideW / 2, y: wy - brickH / 2, w: sideW, h: brickH)
        leftBrick.zPosition = 1
        worldNode.addChild(leftBrick)
        let rightBrick = makeBrickStrip(x: size.width - sideW / 2, y: wy - brickH / 2, w: sideW, h: brickH)
        rightBrick.zPosition = 1
        worldNode.addChild(rightBrick)
    }

    private func makeWallSegment(width: CGFloat, height: CGFloat) -> SKNode {
        let node = SKNode()

        let rect = SKShapeNode(rectOf: CGSize(width: width, height: height))
        rect.fillColor = UIColor(white: 0.75, alpha: 1)
        rect.strokeColor = UIColor(white: 0.5, alpha: 1)
        rect.lineWidth = 1.5
        node.addChild(rect)

        let physBody = SKPhysicsBody(rectangleOf: CGSize(width: width, height: height))
        physBody.isDynamic = false
        physBody.categoryBitMask = wallCat
        physBody.contactTestBitMask = planeCat
        node.physicsBody = physBody

        return node
    }

    // MARK: - Game loop

    override func update(_ currentTime: TimeInterval) {
        guard isRunning else { return }

        let dt = lastUpdate == 0 ? 0 : min(currentTime - lastUpdate, 0.05)
        lastUpdate = currentTime

        // Scroll world upward (plane falls down visually)
        worldY -= scrollSpeed * CGFloat(dt)
        worldNode.position.y = worldY

        // Increase speed over time
        scrollSpeed = min(scrollSpeed + CGFloat(dt) * 4, 350)

        // Move plane left/right toward touch
        if let tx = touchX {
            let targetX = tx
            let currentX = plane.position.x
            let newX = currentX + (targetX - currentX) * min(CGFloat(dt) * 8, 1)
            plane.position.x = max(35, min(size.width - 35, newX))
        }

        // Tilt plane based on horizontal movement
        if let tx = touchX {
            let dx = tx - plane.position.x
            plane.zRotation = CGFloat(atan2(Double(-dx * 0.3), 60))
        } else {
            plane.zRotation *= 0.9
        }

        // Spawn more platforms as we scroll
        let visibleWorldTop = -worldY + size.height
        if nextPlatformY > visibleWorldTop - size.height * 2 {
            spawnPlatform(atWorldY: nextPlatformY)
        }

        // Remove platforms that have scrolled far above screen
        for child in worldNode.children {
            if child.position.y + worldY > size.height + 200 {
                child.removeFromParent()
            }
        }

        // Kill if plane goes off screen sides
        if plane.position.x < 10 || plane.position.x > size.width - 10 {
            endGame()
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
        guard let touch = touches.first else { return }
        touchX = touch.location(in: self).x

        if !isRunning && !(gameState?.isGameOver ?? false) {
            startGame()
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchX = touches.first?.location(in: self).x
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchX = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchX = nil
    }

    // MARK: - Flow

    private func startGame() {
        isRunning = true
        scrollSpeed = 160
        DispatchQueue.main.async { self.gameState?.hasStarted = true }
    }

    private func endGame() {
        guard isRunning else { return }
        isRunning = false
        touchX = nil

        // Flash plane red
        let flash = SKAction.sequence([
            SKAction.colorize(with: .red, colorBlendFactor: 1, duration: 0.1),
            SKAction.colorize(with: .white, colorBlendFactor: 0, duration: 0.1),
            SKAction.repeat(SKAction.sequence([
                SKAction.colorize(with: .red, colorBlendFactor: 1, duration: 0.08),
                SKAction.colorize(with: .white, colorBlendFactor: 0, duration: 0.08)
            ]), count: 3)
        ])
        plane.children.forEach { ($0 as? SKShapeNode).map { $0.run(flash) } }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.gameState?.triggerGameOver()
        }
    }

    override func willMove(from view: SKView) {
        removeAllChildren()
        removeAllActions()
    }
}
