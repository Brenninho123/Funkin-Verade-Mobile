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
	@:unreflective private var __curTouch(get, never):FlxTouch;
	@:unreflective @:noCompletion private inline function get___curTouch()
	{
		if (FlxG.touches.list.length == 0) return null;
		return FlxG.touches.list[FlxG.touches.list.length - 1];
	}

	@:unreflective private var __curAnim:String = 'idle';
	private var __id:String = 'unknown(?)';
	private var __bind:Null<flixel.input.keyboard.FlxKey>;

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

		__bind = ClientPrefs.keyBinds.exists(keyCode) ? ClientPrefs.keyBinds[keyCode][0] : keyCode;
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
		if (Paths.fileExists('images/buttons/$id.png', IMAGE, false, 'mobile'))
		{
			frames = Paths.getSparrowAtlas('buttons/$id', 'mobile');
			__id = id;
		}
		else
		{
			frames = Paths.getSparrowAtlas('buttons/unknown', 'mobile');
			__id = 'unknown($id)';
		}
		
		animation.addByPrefix('idle', '$id idle', 24, true);
		animation.addByPrefix('press', '$id press', 24, false);
		animation.addByIndices('hold', '$id press', [0], "", 24, true);
		animation.play('idle');
		antialiasing = ClientPrefs.data.antialiasing;
		scrollFactor.set();

		FlxG.watch.add(this, 'justPressed', '$__id justPressed');
		FlxG.watch.add(this, 'pressed', '$__id pressed');
		FlxG.watch.add(this, 'justReleased', '$__id justReleased');
	}	

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (!visible || __curTouch == null) return;
		final overlaps:Bool = __curTouch.overlaps(this, this.camera);

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