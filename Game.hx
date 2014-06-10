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

class GameObject {
	public static var spriteHeight = 22;
	public static var spriteWidth = 20;
	public static var tileWidth = 10;
	public var flipped = false;
	public var frame = 0;

	public function copyPixelsFromSpriteSheet(buffer:BitmapData, sheet:BitmapData, dest:Point) {
		var sourceY = 0;
		if (flipped) {
			sourceY = spriteHeight; // Flipped versions of sprites are on second row of sprite sheet
		}

		var source = new Rectangle(spriteWidth * Math.floor(frame), sourceY, spriteWidth, spriteHeight);

		buffer.copyPixels(
			sheet,
			source,
			dest
		);
	}

	public function draw(buffer:BitmapData, sheet:BitmapData) {

	}


}

class Player extends GameObject {
}

class Ground extends GameObject {
	public var groundWidth:Int;

	override public function draw(buffer:BitmapData, sheet:BitmapData, bodyX:Int, bodyY:Int) {
		for (i in 0...groundWidth) {
			copyPixelsFromSpriteSheet(buffer, sheet, new Point(
				bodyX - 10 - (groundWidth-1) * tileWidth + i * tileWidth * 2, 
				bodyY - 11
			));
		}
	}

}

class ProtectTheWall {
	var buffer:BitmapData = null;
	var sheet:BitmapData = null;
	var keys:Map<Int, Bool> = new Map();
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

	// If player is holding on to a ladder, this joint connects him to it.
	var ladderJoint:B2Joint = null;

	function tryGrabbingLadder() {
		// Grab the ladder we are on, if not already grabbing it.
		if (ladderNearUser() != null && ladderJoint == null) {
			trace('would climb');
		}
	}

	// F4 to go to next error
	// Ctrl-0 to go to files
	function moveAlongLadder(amount) {

		var ladderBody = ladderJoint.getBodyB();
		world.destroyJoint(ladderJoint);

		var jointDef = new B2DistanceJointDef();
		jointDef.bodyA = player; 
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

	function isOnLadder() {
		return ladderJoint != null;
	}	

	function jump() {
		// Sample points on bottom left and bottom right to decide whether there is ground below.
		var groundBelow = someBodyAtPoint(player.getWorldCenter().x + tileWidth * 0.4, player.getWorldCenter().y + tileHeight * 0.55)
		|| someBodyAtPoint(player.getWorldCenter().x - tileWidth * 0.4, player.getWorldCenter().y + tileHeight * 0.55);

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
	}

	function tick() {

		world.step(1.0/physScale, 10, 10);
		if (keys[Keyboard.RIGHT] || keys[Keyboard.D]) {

			var ax = player.getWorldCenter().x + tileWidth * 0.55;
			var ay = player.getWorldCenter().y - tileHeight * 0.40;
			var bx = player.getWorldCenter().x + tileWidth * 0.55;
			var by = player.getWorldCenter().y + tileHeight * 0.40;
			var groundOnRight:Bool = someBodyAtPoint(ax, ay) || someBodyAtPoint(bx, by);

//			if (!groundOnRight) {
				player.applyImpulse(new B2Vec2(
					80.0,
					0.0
				), player.getWorldCenter());
//			}
		}

		if (keys[Keyboard.LEFT] || keys[Keyboard.A]) {
/*			var groundOnLeft = someBodyAtPoint(player.getWorldCenter().x - tileWidth * 0.55, player.getWorldCenter().y - tileHeight * 0.40)
	 		|| someBodyAtPoint(player.getWorldCenter().x - tileWidth * 0.55, player.getWorldCenter().y + tileHeight * 0.40);

			if (!groundOnLeft) {*/
				player.applyImpulse(new B2Vec2(
					-80.0,
					0.0
				), player.getWorldCenter());
//			}
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
			letGoOfLadder();
//			jump();
		} else {
			canStillJumpTicks = 0;
		}
	}


	var i = 0;

	function drawBodies() {
		i++;
		var body = world.getBodyList();
		var j = 0;
		while (body != null) {
			var gameObject:GameObject = body.getUserData();

			// There is initially one default body added by Box2D with no attached UserData. Ignore it.
			if (gameObject == null) {
				body = body.getNext();
				continue;
			}

			gameObject.draw(buffer, sheet, body.getPosition().x * screenScale, body.getPosition().y * screenScale);

			if (data['type'] == 'ladder') {
/*				if (ladderJoint == null) {
					trace("create te");
					ladderJoint = createTestJoint(body);
				}*/
			}

			if (data['type'] == 'player') {
/*				if (ladderJoint != null) {
					trace("destroy te");
					world.destroyJoint(ladderJoint);
					ladderJoint = null;
				}
*/
				dest = new Point(Math.floor(body.getPosition().x) * screenScale - 10, Math.floor(body.getPosition().y) * screenScale - 11);

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
				if (Math.abs(body.getLinearVelocity().x) > 0.1) {
					data['flipped'] = body.getLinearVelocity().x < 0;
				}

				var falling = false;
				if (body.getLinearVelocity().y > 1) {
					falling = true;
				}

				if (falling || isOnLadder()) {
					data['frame'] = 5;
				} else {

					if (data['frame'] == 5) {
						data['frame'] = 2;
					}

					data['frame'] += Math.abs(body.getLinearVelocity().x) * 0.025;
					if (data['frame'] > 4) {
						data['frame'] = 1;
					}
				}
			}

			body = body.getNext();
			j++;
		}
	}

	function ladderNearUser():B2Body {
		// Is user over a ladder?
		var ladder = null;
		world.queryPoint(function (fixture:box2D.dynamics.B2Fixture):Bool {
			var userData:Map<String,Dynamic> = fixture.getBody().getUserData();
			if (userData != null) {
				if (userData['type'] == 'ladder') {
					ladder = fixture.getBody();
				}
			}
			return true;
		}, player.getPosition());
		return ladder;
	}

	function refresh() {
		buffer.fillRect(buffer.rect, 0xff0000ff);
		drawBodies();
		world.drawDebugData();
		buffer.draw(debugSprite);
		tick();
	}

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
		var level = Levels.levels[1];

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
    		var game = new ProtectTheWall(untyped loader.content.bitmapData);
    	});
    	loader.load(new flash.net.URLRequest("sheet.png"));
    	
    }
}