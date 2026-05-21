#if mobile
package mobile.objects;

import flixel.input.touch.FlxTouch;
import flixel.util.FlxStringUtil;

class VirtualPad extends FlxSprite
{
	public var justPressed(default, null):Bool;
	public var pressed(default, null):Bool;
	public var justReleased(default, null):Bool;

	public var onPress:Void->Void;
	public var onRelease:Void->Void;
	public var multAlpha(default, set):Float = 1;

	override function set_alpha(value:Float):Float { return super.set_alpha(value * multAlpha); }
	@:noCompletion private function set_multAlpha(mult:Float)
	{
		multAlpha = mult;
		set_alpha(alpha);
		return multAlpha;
	}

	private var __curAnim:String = 'idle';
	private var __id:String = 'unknown(?)';
	private var __bind:Null<flixel.input.keyboard.FlxKey>;
	@:unreflective private var __curTouch:Null<FlxTouch>;

	override function toString():String
	{
		return 'VirtualPadButton' + FlxStringUtil.getDebugString([
			LabelValuePair.weak('button', __id),	
			LabelValuePair.weak('state', __curAnim)	
		]);
	}

	@:unreflective @:noCompletion function __initBind(?keyCode:String)
	{
		if (keyCode == null) return;

		__bind = ClientPrefs.keyBinds.exists(keyCode) ? ClientPrefs.keyBinds[keyCode][0] : FlxKey.fromString(keyCode);
		@:privateAccess if (__bind != NONE)
		{
			onPress = 	() -> FlxG.keys.updateKeyStates(__bind, true);
			onRelease = () -> FlxG.keys.updateKeyStates(__bind, false);
		}
	}

	public function new(x:Float, y:Float, id:String, ?keyCode:String)
	{
		__initBind(keyCode);
		super(x, y);
		if (Paths.fileExists('images/buttons/$id.png', IMAGE, 'mobile'))
		{
			frames = Paths.getSparrowAtlas('buttons/$id', 'mobile');
			__id = id;
		}
		else
		{
			frames = Paths.getSparrowAtlas('buttons/unknown', 'mobile');
			__id = 'unknown($id)';
			id = 'a'; // For the animations
		}
		
		animation.addByPrefix('idle', '$id idle', 24, true);
		animation.addByPrefix('press', '$id press', 24, false);
		animation.addByIndices('hold', '$id press', [0], "", 24, true);
		animation.play('idle');
		antialiasing = ClientPrefs.data.antialiasing;
		scrollFactor.set();

		scale.scale(130 / frameWidth);
		updateHitbox();
	}	

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		for (t in FlxG.touches.list)
		{
			if (t.overlaps(this, this.camera) && __curTouch == null)
			{
				__curTouch = t;
				break;
			}
		}

		if (!visible || __curTouch == null) return;
		var overlaps:Bool = __curTouch.overlaps(this, this.camera);

		if (justPressed = __curTouch.justPressed && overlaps)
		{
			playAnim('press');
			onPress();
		}
		
		if (justReleased = __curTouch.justReleased)
		{
			playAnim('idle');
			onRelease();
		}

		if (!justPressed && (overlaps && (pressed = __curTouch.pressed))) playAnim('hold');

		if (__bind == null) return;
		FlxG.watch.addQuick('actual key pressed $__id', FlxG.keys.checkStatus(__bind, PRESSED));
	}

	public inline function playAnim(anim:String, forced:Bool = false, reversed:Bool = false, startFrame:Int = 0)
	{
		if (__curAnim == anim && !forced) return;

		animation.play(anim, true, reversed, startFrame);
		__curAnim = anim;
	}
}
#end