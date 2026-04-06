#if mobile
package mobile;

import mobile.objects.VirtualPad;
import flixel.util.FlxStringUtil;

enum ActionPadLayout
{
	A;
	B;
	A_B;
	CUSTOM(buttons:Array<String>, mappings:Array<Null<String>>);
	NONE;
}

enum DirectPadLayout
{
	LEFT_RIGHT;
	UP_DOWN;
	FULL;
	DOUBLE_FULL;
	NONE;
}

class VirtualPadHandler extends flixel.FlxBasic
{
	public static inline final NICE_OFFSET:Int = 12;
	public var members:Array<VirtualPad> = [];

	public static var dpadLayout(default, null):DirectPadLayout = NONE;
	public static var actionLayout(default, null):ActionPadLayout = NONE;
	public static var layout(get, never):String;
	@:noCompletion private static inline function get_layout():String { return '$dpadLayout/$actionLayout'; }

	override function set_active(Value:Bool):Bool
	{
		for (m in members)
		{
			m.active = Value;
			m.onRelease();
		}
		return super.set_active(Value);
	}

	public var enabled(default, set):Bool = true;
	@:noCompletion private inline function set_enabled(e):Bool { return enabled = (active = e); }

	public var alpha(default, set):Float = 1;
	@:noCompletion private inline function set_alpha(a):Float
	{
		for (m in members) m.alpha = a;
		return alpha = a;
	}

	public var buttonA:VirtualPad;
	public var buttonB:VirtualPad;
	public var buttonX:VirtualPad;
	public var buttonY:VirtualPad;
	public var otherButtons:Map<String, VirtualPad> = [];

	public var leftButton:VirtualPad; 	public var leftButtonDouble:VirtualPad;
	public var downButton:VirtualPad; 	public var downButtonDouble:VirtualPad;
	public var upButton:VirtualPad; 		public var upButtonDouble:VirtualPad;
	public var rightButton:VirtualPad; 	public var rightButtonDouble:VirtualPad;

	public function new(dpadLayout:DirectPadLayout = NONE, actionLayout:ActionPadLayout = NONE)
	{
		super();
		VirtualPadHandler.dpadLayout = dpadLayout;
		VirtualPadHandler.actionLayout = actionLayout;
		// alpha = ClientPrefs.data.vpadAlpha;

		switch (dpadLayout)
		{
			case LEFT_RIGHT:
				leftButton = new VirtualPad(NICE_OFFSET, 0, "left", "ui_left");
				leftButton.y = (FlxG.height - leftButton.height) - NICE_OFFSET;
				add(leftButton);
				add(rightButton = new VirtualPad((leftButton.x + leftButton.width) + NICE_OFFSET, leftButton.y, "right", "ui_right"));
			case UP_DOWN:
				downButton = new VirtualPad(NICE_OFFSET, 0, "down", "ui_down");
				downButton.y = (FlxG.height - downButton.height) - NICE_OFFSET;
				add(downButton);
				add(upButton = new VirtualPad(downButton.x, (downButton.y - downButton.height) - NICE_OFFSET, "up", "ui_up"));
			case FULL:
				downButton = new VirtualPad(0, 0, "down", "ui_down");
				downButton.y = (FlxG.height - downButton.height) - NICE_OFFSET;
				add(downButton);

				leftButton = new VirtualPad(NICE_OFFSET, 0, "left", "ui_left");
				leftButton.y = (downButton.y - downButton.height);
				downButton.x = (leftButton.x + leftButton.width);
				add(leftButton);

				add(rightButton = new VirtualPad(downButton.x + downButton.width, leftButton.y, "right", "ui_right"));
				add(upButton = new VirtualPad(downButton.x, rightButton.y - rightButton.height, "up", "ui_up"));
			case DOUBLE_FULL:
			case NONE:
		}

		switch (actionLayout)
		{
			case A | B | A_B:
				final choice:String = Std.string(actionLayout);
				if (choice.contains("B"))
				{
					buttonB = new VirtualPad(0, 0, "back", "back");
					buttonB.x = FlxG.width - buttonB.width;
					add(buttonB);
				}

				if (choice.contains("A"))
				{
					buttonA = new VirtualPad(0, 0, "a", "accept");
					buttonA.setPosition((FlxG.width - buttonA.width) - NICE_OFFSET, (FlxG.height - buttonA.height) - NICE_OFFSET);
					add(buttonA);
				}
			/* case A_B:
				buttonB = new VirtualPad(0, 0, "back", "back");
				buttonB.x = FlxG.width - buttonB.width;
				add(buttonB);

				buttonA = new VirtualPad(0, 0, "a", "accept");
				buttonA.setPosition((FlxG.width - buttonA.width) - NICE_OFFSET, (FlxG.height - buttonA.height) - NICE_OFFSET);
				add(buttonA); */
			case CUSTOM(buttons, mappings): for (i=>b in buttons)
				add(otherButtons[b] = new VirtualPad(NICE_OFFSET, NICE_OFFSET, b, mappings[i]));
			case NONE:
		}
	}

	/**
	 * Adds a VirtualPad to this Handler.
	 * This is a nice shorthand to replace the ugly manual `members.push`
	 * @param button 			`VirtualPad` instance to add
	 * @return VirtualPad The added `VirtualPad`
	 */
	public inline function add(button:VirtualPad):VirtualPad
	{
		members.push(button);
		return button;
	}

	override function set_camera(Value:FlxCamera):FlxCamera
	{
		for (m in members) m.camera = Value;
		return super.set_camera(Value);
	}
	override function set_cameras(Value:Array<FlxCamera>):Array<FlxCamera>
	{
		for (m in members) m.cameras = Value;
		return super.set_cameras(Value);
	}

	override function set_exists(Value:Bool):Bool
	{
		for (m in members) m.exists = Value;
		return super.set_exists(Value);
	}
	override function set_visible(Value:Bool):Bool
	{
		for (m in members) m.visible = Value;
		return super.set_visible(Value);
	}

	override function update(elapsed:Float)
	{
		if (members.length == 0 || !exists) return;

		for (m in members)
		{
			if (!m.active || !m.exists) continue;
			m.update(elapsed);
		}
	}

	override function draw()
	{
		if (members.length == 0 || (!visible || !exists)) return;

		for (m in members)
		{
			if (!m.visible || !m.exists) continue;
			m.draw();
		}
	}

	override function destroy()
	{
		super.destroy();
		if (members.length == 0) return;

		for (m in members) m.destroy();
		members.resize(0);
	}

	override function toString():String
	{
		return 'VirtualPad' + FlxStringUtil.getDebugString([
			LabelValuePair.weak("layout", enabled),
			LabelValuePair.weak("enabled", enabled)
		]);
	}
}
#end