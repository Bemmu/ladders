// F4 to go to next error
// Ctrl-0 to go to files

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
import box2D.dynamics.contacts.B2Contact;
import box2D.dynamics.B2ContactListener;
import Levels;

class ContactListener extends B2ContactListener {
    public function new() {
    	super();
    }

    override public function beginContact(contact:B2Contact) {
    }
}

// To add behavior and drawing to Box2D bodies
class GameObject {
	public static var spriteWidth = 20; // in pixels
	public static var spriteHeight = 22;
	public var flipped = false;
	public var frame = 0.0;
	var body:B2Body = null;
	var world:B2World = null;
	var isLadder = false;
	var screenScale:Float;

	public function tick() {
	}

	public function new(body:B2Body, world:B2World, screenScale:Float) {
		this.body = body;
		this.world = world;
		this.screenScale = screenScale;
	}

	public function copyPixelsFromSpriteSheet(buffer:BitmapData, sheet:BitmapData, dest:Point) {
		var sourceY = 0;
		if (flipped) {
			sourceY = spriteHeight; // Flipped versions of sprites are on second row of sprite sheet
		}

		var source = new Rectangle(spriteWidth * Math.floor(frame), sourceY, spriteWidth, spriteHeight);

		buffer.copyPixels(
			sheet,
			source,
			dest,
			null, null, true // alpha
		);
	}

	// Is the center point over a ladder? (regardless if holding on to it)
	function overLadder():B2Body {
		var ladder = null;
		world.queryPoint(function (fixture:box2D.dynamics.B2Fixture):Bool {
			var gameObject:GameObject = fixture.getBody().getUserData();
			if (gameObject != null) {
				if (gameObject.isLadder) {
					ladder = fixture.getBody();
				}
			}
			return true;
		}, body.getPosition());
		return ladder;
	}

	public function draw(buffer:BitmapData, sheet:BitmapData, bodyX:Int, bodyY:Int) {
	}

/*	public function someBodyAtPoint(px, py):Bool {
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
*/
}

class StickMan extends GameObject {

	// If holding on to a ladder, this joint connects him to it.
	var ladderJoint:B2Joint = null;
	var climbSpeed = 0.05;
	var jumpTicks = 5;
	var canStillJumpTicks = 5; // countdown for how long can still continue jumping

	override public function new(body:B2Body, world:B2World, screenScale:Float) {
		super(body, world, screenScale);
		frame = 1;
	}

	function isHoldingOnToLadder() {
		return ladderJoint != null;
	}

	function animate() {
		// Flip sprite if it starts going in a new direction. But when it stops it should remain
		// facing the direction it was previously going towards.
		if (Math.abs(body.getLinearVelocity().x) > 0.1) {
			this.flipped = body.getLinearVelocity().x < 0;
		}

		var falling = false;
		if (body.getLinearVelocity().y > 1) {
			falling = true;
		}

		if (falling || isHoldingOnToLadder()) {
			frame = 5;
		} else {

			if (frame == 5) {
				frame = 2;
			}

			frame += Math.abs(body.getLinearVelocity().x) * (0.025 / 6.0);
			if (frame > 4) {
				frame = 1;
			}
		}
	}

	override public function draw(buffer:BitmapData, sheet:BitmapData, bodyX:Int, bodyY:Int) {
		copyPixelsFromSpriteSheet(buffer, sheet, new Point(
			bodyX - 10, 
			bodyY - 11
		));
		animate();
	}

	function tryGrabbingLadder() {
		var ladder = overLadder();
		if (ladder != null) {
			var jointDef = new B2DistanceJointDef();
			jointDef.bodyA = body; 
			jointDef.bodyB = ladder;
			jointDef.localAnchorA = new B2Vec2(0.0, 0.0); // Will cause mayhem, but let's just try it
			jointDef.localAnchorB = new B2Vec2(0.0, 0.0);
			ladderJoint = world.createJoint(jointDef);			
		}
	}

	function moveAlongLadder(up:Bool) {

		var amount = up ? climbSpeed : -climbSpeed;

		var ladderBody = ladderJoint.getBodyB();
		world.destroyJoint(ladderJoint);

		var jointDef = new B2DistanceJointDef();
		jointDef.bodyA = body; 
		jointDef.bodyB = ladderBody;
		jointDef.localAnchorA = new B2Vec2(0.0, 0.0);
		jointDef.localAnchorB = new B2Vec2(0.0, 0.0);
		return world.createJoint(jointDef);

	}

	// Big arrows can be shot up to actually remove tiles so the player can fall to the ground.trace
	// Could drop ... fuck it stop having ideas and start doing prototyping.

	function letGoOfLadder() {
		world.destroyJoint(ladderJoint);
		ladderJoint = null;
	}

/*	function jump() {
		// Sample points on bottom left and bottom right to decide whether there is ground below.
		var groundBelow = someBodyAtPoint(player.getWorldCenter().x + GameObject.tileWidth * 0.4, player.getWorldCenter().y + GameObject.tileHeight * 0.55)
		|| someBodyAtPoint(player.getWorldCenter().x - GameObject.tileWidth * 0.4, player.getWorldCenter().y + GameObject.tileHeight * 0.55);

		if (groundBelow || isOnLadder()) {
			canStillJumpTicks = jumpTicks;
		}

		if (isOnLadder()) {
			letGoOfLadder();
		}

		// Can hover in the air a bit after jumping to control jumping height
		canStillJumpTicks--;
		if (canStillJumpTicks > 0) {
			player.applyImpulse(new B2Vec2(
				0.0,
				-jumpImpulse
			), player.getWorldCenter());
		}
	}*/
}

class Player extends StickMan {
	var keys:Map<Int, Bool> = new Map();
	
	override public function new(body:B2Body, world:B2World, screenScale:Float, keys:Map<Int, Bool>) {
		super(body, world, screenScale);
		this.keys = keys;
	}

	override public function tick() {
		if (keys[Keyboard.RIGHT] || keys[Keyboard.D]) {

			var ax = body.getWorldCenter().x + GameObject.spriteWidth/screenScale * 0.55;
			var ay = body.getWorldCenter().y - GameObject.spriteHeight/screenScale * 0.40;
			var bx = body.getWorldCenter().x + GameObject.spriteWidth/screenScale * 0.55;
			var by = body.getWorldCenter().y + GameObject.spriteHeight/screenScale * 0.40;
//			var groundOnRight:Bool = someBodyAtPoint(ax, ay) || someBodyAtPoint(bx, by);

//			if (!groundOnRight) {
				body.applyImpulse(new B2Vec2(
					80.0,
					0.0
				), body.getWorldCenter());
//			}
		}

		if (keys[Keyboard.LEFT] || keys[Keyboard.A]) {
/*			var groundOnLeft = someBodyAtPoint(player.getWorldCenter().x - tileWidth * 0.55, player.getWorldCenter().y - tileHeight * 0.40)
	 		|| someBodyAtPoint(player.getWorldCenter().x - tileWidth * 0.55, player.getWorldCenter().y + tileHeight * 0.40);

			if (!groundOnLeft) {*/
				body.applyImpulse(new B2Vec2(
					-80.0,
					0.0
				), body.getWorldCenter());
//			}
		}

		if (keys[Keyboard.UP]||keys[Keyboard.W]) {
			if (isHoldingOnToLadder()) {
				moveAlongLadder(true);
			} else {
				tryGrabbingLadder();
			}
		}

		if (keys[Keyboard.DOWN]||keys[Keyboard.S]) {
			if (isHoldingOnToLadder()) {
				moveAlongLadder(false);
			}
		}

		if (keys[Keyboard.SPACE]||keys[Keyboard.Z]||keys[Keyboard.X]) {
//			letGoOfLadder();
//			jump();
		} else {
			canStillJumpTicks = 0;
		}
	}
}

class Ground extends GameObject {
	public var groundWidth:Int;

	override public function new(body:B2Body, world:B2World, screenScale:Float, groundWidth:Int) {
		super(body, world, screenScale);
		this.groundWidth = groundWidth;
	}

	override public function draw(buffer:BitmapData, sheet:BitmapData, bodyX:Int, bodyY:Int) {
		for (i in 0...groundWidth) {
			copyPixelsFromSpriteSheet(buffer, sheet, new Point(
				bodyX - 10 - (groundWidth-1) * GameObject.spriteWidth/screenScale + i * GameObject.spriteWidth/2 * 2, 
				bodyY - 11
			));
		}
	}

}

class Ladder extends Game.GameObject {
	override public function new(body:B2Body, world:B2World, screenScale:Float) {
		super(body, world, screenScale);
		isLadder = true;
	}

	override public function draw(buffer:BitmapData, sheet:BitmapData, bodyX:Int, bodyY:Int) {
		buffer.fillRect(new Rectangle(bodyX, bodyY, 10, 10), 0xff00ffff);

		// To draw, need to find the corners.
		// To find the corners, need ... physics body info and screenscale.

	}
}

class ProtectTheWall {
	var buffer:BitmapData = null;
	var sheet:BitmapData = null;
	var keys:Map<Int, Bool> = new Map();
	var screenScale = 20; // how many times larger assets should be shown on screen relative to physics coordinates

	// tileWidth and height are in pixels

	var world:B2World;
	var debugSprite:Sprite;
	var player:B2Body = null;
	var jumpImpulse = 350;
	var ladderGrabDistance = 4;

	function tick() {
		world.step(1.0/60.0, 10, 10);

		var body = world.getBodyList();
		var gameObject:GameObject;

		while (body != null) {
			gameObject = body.getUserData();
			if (gameObject != null) {
				gameObject.tick();
			}
			body = body.getNext();
		}
	}

	var i = 0;

	function drawBodies() {
		i++;
		var body = world.getBodyList();
		while (body != null) {
			var gameObject:GameObject = body.getUserData();

			// There is initially one default body added by Box2D with no attached UserData. Ignore it.
			if (gameObject == null) {
				body = body.getNext();
				continue;
			}

			gameObject.draw(buffer, sheet, Math.floor(body.getPosition().x * screenScale), Math.floor(body.getPosition().y * screenScale));
			gameObject.tick();

			body = body.getNext();
		}
	}

	function refresh() {
		buffer.fillRect(buffer.rect, 0xff0000ff);
//		drawBodies();
		world.drawDebugData();
		buffer.draw(debugSprite);
		tick();
	}

	function createGroundAt(tileX:Float, tileY:Float, groundWidth:Int) {
		var bodyDef = new B2BodyDef();
		bodyDef.fixedRotation = true;

		// "x2d sets the position of the center of an object, not the top left like normal"
		// Add a bit to the position so that a small nudge won't move immovable things to the next pixel.
		bodyDef.position.set(
			(0.05 + tileX)/screenScale, 
			(0.05 + tileY)/screenScale
		);

		var boxShape = new B2PolygonShape();

		// Takes half-width and half-height
		boxShape.setAsBox(
			(GameObject.spriteWidth * groundWidth * 0.5)/screenScale,
			(GameObject.spriteHeight * 0.5)/screenScale
		);

		var fixtureDef = new B2FixtureDef();
		fixtureDef.shape = boxShape;
		fixtureDef.friction = 0.2;
		fixtureDef.density = 1.0;
		fixtureDef.filter.categoryBits = 0x0001;
		fixtureDef.filter.maskBits = 0x0001 | 0x0002 | 0x0004;

		var body = world.createBody(bodyDef);
		var ground = new Ground(body, world, screenScale, groundWidth);
		body.setUserData(ground);

		body.createFixture(fixtureDef);
	}

	function createPlayerAt(tileX:Float, tileY:Float) {
		var bodyDef = new B2BodyDef();
		bodyDef.fixedRotation = true;
		bodyDef.position.set(tileX/screenScale, tileY/screenScale);
		var fixtureDef = new B2FixtureDef();

		var boxShape = new B2PolygonShape();
		boxShape.setAsBox(
			(GameObject.spriteWidth * 0.9 * 0.5)/screenScale, 
			(GameObject.spriteHeight * 0.92 * 0.5)/screenScale
		);

		fixtureDef.filter.categoryBits = 0x0002;
		fixtureDef.filter.maskBits = 0x0001 | 0x0002;
		fixtureDef.shape = boxShape;
		fixtureDef.friction = 0.5;
		fixtureDef.density = 1.0;

		bodyDef.type = B2Body.b2_dynamicBody;
		bodyDef.allowSleep = false;

		var body = world.createBody(bodyDef);
		var player = new Player(body, world, screenScale, keys);
		body.setUserData(player);

		body.createFixture(fixtureDef);
		return body;
	}

	function createLadderAt(tileX:Float, tileY:Float, height:Float) {
		var bodyDef = new B2BodyDef();
		bodyDef.fixedRotation = false;
		bodyDef.position.set(
			tileX/screenScale, 
			(tileY - height*GameObject.spriteHeight*0.5)/screenScale
		);
		var fixtureDef = new B2FixtureDef();

		var boxShape = new B2PolygonShape();
		boxShape.setAsBox(
			(GameObject.spriteWidth * 0.5)/screenScale, 
			(GameObject.spriteHeight * 0.5 * height)/screenScale
		);

		// I'm very confused by these two coordinate systems.
		// 

		fixtureDef.filter.categoryBits = 0x0004;
		fixtureDef.filter.maskBits = 0x0001 | 0x0004;
		fixtureDef.shape = boxShape;
		fixtureDef.friction = 0.5;
		fixtureDef.density = 1.0;

		bodyDef.type = B2Body.b2_dynamicBody;
		bodyDef.allowSleep = false;

		var body = world.createBody(bodyDef);
		var ladder = new Ladder(body, world, screenScale);
		body.setUserData(ladder);

		body.createFixture(fixtureDef);

		return body;
	}

	function makeLevel() {
		var ladderAlreadyCreated:Map<String, Bool> = new Map();
		var level = Levels.levels[1];

		var y = 15; // x and y refer to the level string here
		while (y > 0) {
			y--;

			var prevCh = null;
			var groundWidth = 0; // for making larger physics blocks for ground (i.e. 10x1 instead of ten 1x1)

			for (x in 0...28) {

				var ch = level.charAt(y * 29 + x); // level is represented by characters, look at Levels.hx if you don't get it
				var nextCh = level.charAt(y * 29 + x + 1); // lookahead
				var physX:Float = (x + 0.5) * GameObject.spriteWidth;
				var physY:Float = (y + 0.5) * GameObject.spriteHeight;

				// If there are several ground tiles next to each other then create one bigger continuous
				// block. Otherwise sliding on it won't work properly (some Box2D quirk?). 
				if (ch == 'x') {
					groundWidth += 1;
				}
				if (ch != nextCh) {
					if (ch == 'x') {
						var st:Float = physX - (groundWidth - 1) * GameObject.spriteWidth * 0.5;
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

	var contactListener:B2ContactListener;

	public function new(sheet:flash.display.BitmapData) {
		this.sheet = sheet;

		world = new B2World(new B2Vec2(0.0, 10.0), true);

		contactListener = new ContactListener();
		world.setContactListener(contactListener);
		makeLevel();
		//player = createPlayerAt(100.0, 0.0);
		initKeyboard();

		buffer = new BitmapData(flash.Lib.current.stage.stageWidth, flash.Lib.current.stage.stageHeight);
		var mc:flash.display.MovieClip = flash.Lib.current;
		mc.addChild(new Bitmap(buffer));

		flash.Lib.current.stage.addEventListener(Event.ENTER_FRAME, OnEnter);
		debugSetup();
	}

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

	function createTestJoint(bodyB:B2Body):B2Joint {
		if (player == null) {
			trace("Player was NULL when trying to create ladder joint.");
			return null;
		}
		var jointDef = new B2DistanceJointDef();
		jointDef.bodyA = player; 
		jointDef.bodyB = bodyB;
		jointDef.localAnchorA = new B2Vec2(0.0, 0.0); // Will cause mayhem, but let's just try it
		jointDef.localAnchorB = new B2Vec2(0.0, 0.0);
		var joint = world.createJoint(jointDef);
		return joint;
	}
}

class Game {
    static function main() {
    	var loader = new flash.display.Loader();
    	loader.contentLoaderInfo.addEventListener(flash.events.Event.COMPLETE, function(_) {
    		var game = new ProtectTheWall(untyped loader.content.bitmapData);
    	});
    	loader.load(new flash.net.URLRequest("sheet.png"));
    }
}