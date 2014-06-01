import box2D.foo.*;
import flash.display.*;
import flash.events.*;
import flash.geom.*;
import flash.utils.*;
import flash.ui.*;
import box2D.dynamics.*;
import box2D.dynamics.joints.*;
import box2D.collision.*;
import box2D.collision.shapes.*;
import box2D.common.math.*;
import box2D.dynamics.contacts.*;

class IHateLadders {
	var spriteHeight = 22;
	var spriteWidth = 20;
	var buffer:BitmapData = null;
	var sheet:BitmapData = null;
	var keys:Map<Int, Bool> = new Map();
	var tileWidth = 10;
	var tileHeight = 11;
	var physScale = 10.0;
	var screenScale = 2.0; // how many times larger assets should be shown on screen relative to their native
	var world:B2World;
	var debugSprite:Sprite;
	var player:B2Body = null;
	var jumpTicks = 5;
	var canStillJumpTicks = 5; // countdown for how long can still continue jumping
	var jumpImpulse = 350;
	var ladderGrabDistance = 4;
	var climbSpeed = 0.05;

	// Dict key is the ladder ID character in the level. Value is an array of ladder segments, each
	// one a dictionary with x and y coordinates.
	var ladders = new Map<String, Array<Map<String, Float>>>();

	// Information about the ladder the player is currently on.
	var currentLadderKey:String;
	var currentLadderSegmentIndex:Int;
	var currentLadderT:Float; // Position along ladder

	// Make player snap to the given ladder at position t along the ladder.
	function grabLadder(ladderKey:String, ladderSegmentIndex:Int, t:Float) {
		var ladder = ladders[ladderKey][ladderSegmentIndex];
		var nearX = ladder['startX'] + (ladder['endX'] - ladder['startX']) * t;
		var nearY = ladder['startY'] + (ladder['endY'] - ladder['startY']) * t;

		var shape = new Shape();
		shape.graphics.lineStyle(1, Math.floor(Math.random()*255) + (Math.floor(Math.random()*255)<<8) + (Math.floor(Math.random()*255)<<16), 10);
		shape.graphics.drawCircle(nearX * screenScale, nearY * screenScale, 10);
		shape.graphics.moveTo(ladder['startX'] * screenScale, ladder['startY'] * screenScale);
		shape.graphics.lineTo(ladder['endX'] * screenScale, ladder['endY'] * screenScale);
		buffer.draw(shape);

		currentLadderKey = ladderKey;
		currentLadderSegmentIndex = ladderSegmentIndex;
		currentLadderT = t;
	}

	// http://stackoverflow.com/questions/849211/shortest-distance-between-a-point-and-a-line-segment
	function sqr(x:Float):Float {
		return x * x;
	}
	function dist2(a:Point, b:Point):Float { 
		return sqr(a.x - b.x) + sqr(a.y - b.y);
	}
	function distToSegmentSquared(p:Point, v:Point, w:Point) {
		var l2:Float = dist2(v, w);
		if (l2 == 0) return [0, dist2(p, v)];
		var t:Float = ((p.x - v.x) * (w.x - v.x) + (p.y - v.y) * (w.y - v.y)) / l2;
		if (t < 0) return [0, dist2(p, v)];
		if (t > 1) return [1, dist2(p, w)];
		return [t, dist2(p, new Point(v.x + t * (w.x - v.x), v.y + t * (w.y - v.y)))];
	}
	function distToSegment(p, v, w) { 
		var ret = distToSegmentSquared(p, v, w); 
		return [ret[0], Math.sqrt(ret[1])]; 
	}	

	function tryGrabbingLadder() {

		// See if any ladder segment is close enough to grab
		var minDist = 999999.0;
		var minDistLadderKey:String = null;
		var minDistSegmentIndex = -1;
		var minT = -1.0;

		for (key in ladders.keys()) {
			var ladder = ladders[key];
			for (i in 0...ladder.length) {
				// Closest point to line segment?
				var playerPos:Point = new Point(player.getPosition().x, player.getPosition().y);
				var d = distToSegment(playerPos, new Point(ladder[i]['startX'], ladder[i]['startY']), new Point(ladder[i]['endX'], ladder[i]['endY']));
				var dist = d[1];
				if (dist < minDist) {
					minDistLadderKey = key;
					minDistSegmentIndex = i;
					minDist = dist;
					minT = d[0]; // How much along the ladder is the nearest point
				}
			}
		}

		if (minDist < ladderGrabDistance) {
			grabLadder(minDistLadderKey, minDistSegmentIndex, minT);
		}
	}

	function moveAlongLadder(amount) {
		currentLadderT += amount;

		// If this reached end of this ladder, then either cannot move or
		// proceed to next ladder segment.
		if (currentLadderT > 1) {

			// If there is a next segment to hop on to, then continue movement there.
			var segmentsInCurrentLadder = ladders[currentLadderKey].length;
			if (currentLadderSegmentIndex + 1 < segmentsInCurrentLadder) {
				currentLadderSegmentIndex += 1;
				currentLadderT -= 1;
			} else {
				// Otherwise cannot move
				currentLadderT = 1;
			}
		}

		// Similar for going backwards on the ladder
		if (currentLadderT < 0) {
			if (currentLadderSegmentIndex > 0) {
				currentLadderSegmentIndex -= 1;
				currentLadderT += 1;
			} else {
				currentLadderT = 0;
			}
		}
	}

	function stickToLadder() {
		var ladder = ladders[currentLadderKey][currentLadderSegmentIndex];
		var grabPointX = ladder['startX'] + (ladder['endX'] - ladder['startX']) * currentLadderT;
		var grabPointY = ladder['startY'] + (ladder['endY'] - ladder['startY']) * currentLadderT;
		player.setPosition(new B2Vec2(grabPointX, grabPointY));
	}	

	function letGoOfLadder() {
		currentLadderKey = null;
		currentLadderSegmentIndex = -1;
		currentLadderT = -1.0;
		jump();
	}

	function isOnLadder() {
		return currentLadderKey != null;
	}	

	function jump() {
		// Sample points on bottom left and bottom right to decide whether there is ground below.
		var groundBelow = someBodyAtPoint(player.getWorldCenter().x + tileWidth * 0.4, player.getWorldCenter().y + tileHeight * 0.55)
		|| someBodyAtPoint(player.getWorldCenter().x - tileWidth * 0.4, player.getWorldCenter().y + tileHeight * 0.55);

		if (groundBelow||isOnLadder()) {
			canStillJumpTicks = jumpTicks;
		}

		if (isOnLadder()) {
			letGoOfLadder();
		}

		canStillJumpTicks--;
		if (canStillJumpTicks > 0) {
			player.applyImpulse(new B2Vec2(
				0.0,
				-jumpImpulse
			), player.getWorldCenter());
		}
	}

	function tick() {

		// If player is grabbing a ladder currently, then make sure they are at the grab point.
		if (currentLadderKey != null) {
			stickToLadder();
		}

		world.step(1.0/physScale, 10, 10);
		if (keys[Keyboard.RIGHT]||keys[Keyboard.D]) {

			var ax = player.getWorldCenter().x + tileWidth * 0.55;
			var ay = player.getWorldCenter().y - tileHeight * 0.40;
			var bx = player.getWorldCenter().x + tileWidth * 0.55;
			var by = player.getWorldCenter().y + tileHeight * 0.40;
			var groundOnRight:Bool = someBodyAtPoint(ax, ay) || someBodyAtPoint(bx, by);

			if (!groundOnRight) {
				player.applyImpulse(new B2Vec2(
					80.0,
					0.0
				), player.getWorldCenter());
			}
		}

		if (keys[Keyboard.LEFT] || keys[Keyboard.A]) {
			var groundOnLeft = someBodyAtPoint(player.getWorldCenter().x - tileWidth * 0.55, player.getWorldCenter().y - tileHeight * 0.40)
	 		|| someBodyAtPoint(player.getWorldCenter().x - tileWidth * 0.55, player.getWorldCenter().y + tileHeight * 0.40);

			if (!groundOnLeft) {
				player.applyImpulse(new B2Vec2(
					-80.0,
					0.0
				), player.getWorldCenter());
			}
		}

		if (keys[Keyboard.UP]||keys[Keyboard.W]) {
			if (isOnLadder()) {
				moveAlongLadder(climbSpeed);
			} else {
				tryGrabbingLadder();
			}
		}

		if (keys[Keyboard.DOWN]||keys[Keyboard.S]) {
			if (isOnLadder()) {
				moveAlongLadder(-climbSpeed);
			}
		}

		if (keys[Keyboard.SPACE]||keys[Keyboard.Z]||keys[Keyboard.X]) {
			jump();
		} else {
			canStillJumpTicks = 0;
		}
	}

	function drawLadders() {
		var shape = new Shape();

		// Iterate ladders
		for (ladder in ladders) {
			// Draw ladder segments
			for (i in 0...ladder.length) {//  var i = 0; i < ladder.length; i++) {

/*				var source:Rectangle, dest:Point;
				dest = new Point(ladder[i]['startX'] * screenScale, ladder[i]['startY'] * screenScale);
				var sourceY = 0;
				source = new Rectangle(spriteWidth * 0, sourceY, spriteWidth, spriteHeight);

				buffer.copyPixels(
					sheet,
					source,
					dest
				);
*/
				shape.graphics.lineStyle(1, Math.floor(Math.random()*255) + (Math.floor(Math.random()*255)<<8) + (Math.floor(Math.random()*255)<<16), 1);
				shape.graphics.drawCircle(ladder[i]['startX'] * screenScale, ladder[i]['startY'] * screenScale, 10);
				shape.graphics.moveTo(ladder[i]['startX'] * screenScale, ladder[i]['startY'] * screenScale);
				shape.graphics.lineTo(ladder[i]['endX'] * screenScale, ladder[i]['endY'] * screenScale);
			}
		}
		buffer.draw(shape);
	}

	function drawBodies() {

		var bb = world.getBodyList();
		while ((bb = bb.getNext()) != null) {
			var data:Map<String,Dynamic> = bb.getUserData();
			if (data == null) continue;

			var sourceY = 0;
			if (data['flipped']) {
				sourceY = spriteHeight;
			}

			var source:Rectangle, dest:Point;
			source = new Rectangle(spriteWidth * Math.floor(data['frame']), sourceY, spriteWidth, spriteHeight);

			// One physics box can take several sprite sheet items to represent
			if (data['type'] == 'ground') {
				for (i in 0...data['groundWidth']) {
					dest = new Point(bb.getPosition().x * screenScale - 10 - (data['groundWidth']-1) * tileWidth + i * tileWidth * 2, bb.getPosition().y * screenScale - 11);
					buffer.copyPixels(
						sheet,
						source,
						dest
					);
				}
			}

			if (data['type'] == 'ladder') {
			}

			if (data['type'] == 'player') {
				dest = new Point(Math.floor(bb.getPosition().x) * screenScale - 10, Math.floor(bb.getPosition().y) * screenScale - 11);

				buffer.copyPixels(
					sheet,
					source,
					dest,
					null, null, true // alpha
				);
			}

			if (data['type'] == 'player') {

				// Flip sprite if it starts going in a new direction. But when it stops it should remain
				// facing the direction it was previously going towards.
				if (Math.abs(bb.getLinearVelocity().x) > 0.1) {
					data['flipped'] = bb.getLinearVelocity().x < 0;
				}

				var falling = false;
				if (bb.getLinearVelocity().y > 1) {
					falling = true;
				}

				if (falling||currentLadderKey!=null) {
					data['frame'] = 5;
				} else {

					if (data['frame'] == 5) {
						data['frame'] = 2;
					}

					data['frame'] += Math.abs(bb.getLinearVelocity().x) * 0.025;
					if (data['frame'] > 4) {
						data['frame'] = 1;
					}
				}
			}
		}
	}

	function refresh() {
		buffer.fillRect(buffer.rect, 0xff0000ff);
		drawBodies();
//		drawLadders();
		world.drawDebugData();
		buffer.draw(debugSprite);
		tick();
	}

	var levels = [
'xx..........................
..x.@.......................
..x.........................
..xxx.......................
....x.......................
............................
............................
...............@............
...............x............
............................
............................
7...8xxxxxxx9xxxxxx5xxxxx6xx
7...........9............6..
7...........9............6..
xxxxxxxxxxxxxxxxxxxxxxxxxxxx',

'............................
............................
............................
............................
........1........2....3.....
........1...@....2....3.....
........1........2....3.....
........1........2....3.....
........1........2....3.....
........1........2....3.....
........1........2....3.....
........1........2....3.....
........1........2....3.....
........1........2....3.....
xxxxxxxxxxxxxxxxxxxxxxxxxxxx',

'............................
xxx.............xxxx3xxxxxxx
..xx...........xx...3.......
...xx.........xx....3.......
...xxx.......xxx....3.......
xx1xxxx.....xxxx4xxx3xxxxxxx
..1...xx...xx...4...........
..1....xx2xx....4...........
7xxx8....2.....x4xx5xxx.....
7...8..............5........
7...8..............5........
7...8xxxxxxx9xxxxxx5xxxxx6xx
7...........9..@.........6..
7...........9............6..
xxxxxxxxxxxxxxxxxxxxxxxxxxxx',

'............................
............................
...........................x
...................xxx..x..x
...............xxxxx.x.....x
............xxxx.....x....xx
xxxxxx...............x...xxx
x....x......xx...x....x..xxx
x....x..xx...........x.....x
x....xxxx..........xxxxxxxxx
x..........................x
x..xxxxxxxxx9x...xx5xxxxx6xx
x...........9..@...5.....6.x
x...........9......5.....6.x
xxxxxxx.x.xxxxxxxxxxxxxxxxxx'
	];

// Use the ladder drawing method to do title screen logo!

	function createGroundAt(tileX:Float, tileY:Float, groundWidth:Int) {
		var bodyDef = new B2BodyDef();
		bodyDef.fixedRotation = true;

		// "x2d sets the position of the center of an object, not the top left like normal"

		// Add a bit to the position so that a small nudge won't move immovable things to the next pixel.
		bodyDef.position.set(0.05 + tileX + groundWidth * tileWidth * 0.5 - tileWidth * 0.5, 0.05 + tileY);

		var boxShape = new B2PolygonShape();
		boxShape.setAsBox(tileWidth * groundWidth * 0.5, tileHeight * 0.5);
		var fixtureDef = new B2FixtureDef();
		fixtureDef.shape = boxShape;
		fixtureDef.friction = 0.2;
		fixtureDef.density = 1.0;
		fixtureDef.filter.categoryBits = 0x0001;
		fixtureDef.filter.maskBits = 0x0001 | 0x0002 | 0x0004;

		var userData:Map<String,Dynamic> = [
			'type' => 'ground',
			'frame' => 0,
			'flipped' => false,
			'groundWidth' => groundWidth
		];
		bodyDef.userData = userData;

		var body = world.createBody(bodyDef);
		body.createFixture(fixtureDef);
	}

	function createPlayerAt(tileX:Float, tileY:Float) {
		var bodyDef = new B2BodyDef();
		bodyDef.fixedRotation = true;
		bodyDef.position.set(tileX, tileY);
		var fixtureDef = new B2FixtureDef();

		var boxShape = new B2PolygonShape();
		boxShape.setAsBox(tileWidth * 0.45, tileHeight * 0.46);

		fixtureDef.filter.categoryBits = 0x0002;
		fixtureDef.filter.maskBits = 0x0001 | 0x0002;
		fixtureDef.shape = boxShape;
		fixtureDef.friction = 0.5;
		fixtureDef.density = 1.0;

		bodyDef.type = B2Body.b2_dynamicBody;
		bodyDef.allowSleep = false;

		var userData:Map<String,Dynamic> = [
			'type' => 'player',
			'frame' => 1,
			'flipped' => false
		];
		bodyDef.userData = userData;

		var body = world.createBody(bodyDef);
		body.createFixture(fixtureDef);
		return body;
	}

	function createLadderAt(tileX:Float, tileY:Float, height:Float) {
		var bodyDef = new B2BodyDef();
		bodyDef.fixedRotation = false;
		bodyDef.position.set(tileX, tileY - tileHeight * 0.5 * height);
		var fixtureDef = new B2FixtureDef();

		var boxShape = new B2PolygonShape();
		boxShape.setAsBox(tileWidth * 0.5, tileHeight * 0.5 * height);

		fixtureDef.filter.categoryBits = 0x0004;
		fixtureDef.filter.maskBits = 0x0001 | 0x0004;
		fixtureDef.shape = boxShape;
		fixtureDef.friction = 0.5;
		fixtureDef.density = 1.0;

		bodyDef.type = B2Body.b2_dynamicBody;
		bodyDef.allowSleep = false;

		var userData:Map<String,Dynamic> = [
			'type' => 'ladder'
		];
		bodyDef.userData = userData;

		var body = world.createBody(bodyDef);
		body.createFixture(fixtureDef);
		return body;
	}

	function makeLevel() {
		var ladderAlreadyCreated:Map<String, Bool> = new Map();
		var level = levels[1];

		var y = 15;
		while (y > 0) {
			y--;

			var prevCh = null;
			var groundWidth = 0;

			for (x in 0...28) {

				var ch = level.charAt(y * 29 + x);
				var nextCh = level.charAt(y * 29 + x + 1);
				var physX:Float = (x + 0.5) * tileWidth;
				var physY:Float = (y + 0.5) * tileHeight;

				// If there are several ground tiles next to each other then create one bigger continuous
				// block. Otherwise sliding on it won't work properly (some Box2D quirk?). 
				if (ch == 'x') {
					groundWidth += 1;
				}
				if (ch != nextCh) {
					if (ch == 'x') {
						var st:Float = physX - (groundWidth - 1) * tileWidth;
						createGroundAt(st, physY, groundWidth);
					}
					groundWidth = 0;
				}

				if (ch == '@') {
					player = createPlayerAt(physX, physY);
				}

				// Digits signify ladder pieces
				var isLadder = ch == '1'||ch == '2'||ch == '3'||ch == '4'||ch == '5'||ch == '6'||ch == '7'||ch == '8'||ch == '9';
				if (isLadder) {
					// Stop if this ladder has already been created
					if (!ladderAlreadyCreated[ch]) {

						// Peek ahead how high this ladder should be
						var yLookAhead = y;
						while (yLookAhead > 0) {
							yLookAhead--;
							if (level.charAt(yLookAhead * 29 + x) != ch) {
								break;
							}
						}
						var ladderHeight = y - yLookAhead;

						createLadderAt(physX, physY, ladderHeight);
					}
					ladderAlreadyCreated[ch] = true;
				}

/*				if (isLadder) {
					if (!ladders.exists(ch)) {
						ladders[ch] = [];
					}
					ladders[ch].push([
						'startX' => (x + 0.5) * tileWidth, 
						'startY' => (y + 1.0) * tileHeight,
						'endX' => (x + 0.5) * tileWidth, 
						'endY' => (y) * tileHeight
					]);
				}*/
			}
		}
	}

	function initKeyboard() {
		flash.Lib.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, function (e) {
			keys[e.keyCode] = true;
		});
		flash.Lib.current.stage.addEventListener(KeyboardEvent.KEY_UP, function (e) {
			keys[e.keyCode] = false;
		});
	}

	function OnEnter(e:flash.events.Event) {
		refresh();
	}

	function debugSetup() {
		debugSprite = new Sprite();
		var debugDraw = new B2DebugDraw();
		debugDraw.setSprite(debugSprite);
		debugDraw.setDrawScale(screenScale);
		debugDraw.setFillAlpha(0.3);
		debugDraw.setLineThickness(2.0);
		debugDraw.setFlags(B2DebugDraw.e_shapeBit | B2DebugDraw.e_jointBit);
		world.setDebugDraw(debugDraw);
	}

	public function new(sheet:flash.display.BitmapData) {
		this.sheet = sheet;

		world = new B2World(new B2Vec2(0.0, 10.0), true);
		makeLevel();
		initKeyboard();

		buffer = new BitmapData(flash.Lib.current.stage.stageWidth, flash.Lib.current.stage.stageHeight);
		var mc:flash.display.MovieClip = flash.Lib.current;
		mc.addChild(new Bitmap(buffer));

		flash.Lib.current.stage.addEventListener(Event.ENTER_FRAME, OnEnter);
		debugSetup();
	}

	// Welcome to your new job as ladder inspector.
	// Your job is simple: climb every ladder to ensure safety!

	var overlaps:Bool;
	function callback(fixture:B2Fixture) {
		var userData:Map<String,Dynamic> = fixture.getBody().getUserData();
		var type:String = userData['type'];
		if (type == 'player') {
			return true; // continue to next fixture
		}

    	overlaps = true;
    	return false; // don't continue to next fixture
	}

	public function someBodyAtPoint(px, py):Bool {
	    // Make a small box.
	    var px2 = px;
	    var py2 = py;
	    var pointVec:B2Vec2 = new B2Vec2();
	    pointVec.set(px2, py2);
	    var aabb = new B2AABB();
	    aabb.lowerBound.set(px2 - 0.001, py2 - 0.001);
	    aabb.upperBound.set(px2 + 0.001, py2 + 0.001);
	    
	    // Query the world for overlapping shapes.
	    var k_maxCount:Int = 10;
	    var shapes = [];

	    overlaps = false;
	    world.queryAABB(callback, aabb);
	    return overlaps;
	}

}

class Game {
    static function main() {
    	var loader = new flash.display.Loader();
    	loader.contentLoaderInfo.addEventListener(flash.events.Event.COMPLETE, function(_) {
    		var game = new IHateLadders(untyped loader.content.bitmapData);
    	});
    	loader.load(new flash.net.URLRequest("sheet.png"));
    	
    }
}