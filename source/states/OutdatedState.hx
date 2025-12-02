package states;

import flixel.effects.FlxFlicker;
import flixel.util.typeLimit.NextState.InitialState;

class OutdatedState extends flixel.FlxState
{
	public static var updateVersion:String = "Unknown";
	var blockInput:Bool = false;
	var curSelected:Int = 0;

	final initialState:InitialState;
	var texts:FlxTypedSpriteGroup<FlxText>;

	@:allow(Main)
	function new(initialState:InitialState)
	{
		this.initialState = initialState;
		super();	
	}

	override function create()
	{
		FlxG.mouse.visible = false;
		super.create();

		texts = new FlxTypedSpriteGroup<FlxText>();
		add(texts);

		var warnText:FlxText = new FlxText(0, 0, FlxG.width,
			'Hey dude, you have an outdated version of the mod!\n
			I\'d recommend you update to the latest to not miss out on any patches or bugfixes.\n
			(Current: ${lime.app.Application.current.meta["version"]} | Latest: $updateVersion)\n
			Do you want to update the mod?');
		warnText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		warnText.screenCenter();
		warnText.active = false;
		texts.add(warnText);

		var keys:Array<String> = ["Yes", "No"];
		for (i in 0...keys.length)
		{
			var button = new FlxText(0, (warnText.y + warnText.height) + 24, 0, keys[i]);
			button.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
			button.screenCenter(X).x -= button.width;
			button.x += button.width * i;
			button.active = false;
			texts.add(button);
		}
		keys.resize(0);

		changeSelection(0);
	}

	override function update(elapsed:Float)
	{
		if (blockInput)
		{
			super.update(elapsed);
			return;
		}
		
		final left_p:Bool = Controls.instance.UI_LEFT_P;
		if (left_p || Controls.instance.UI_RIGHT_P)
		{
			FlxG.sound.play(Paths.sound("scrollMenu"));
			changeSelection(1 * (left_p ? -1 : 1));
		}

		if (Controls.instance.ACCEPT)
		{
			blockInput = true;
			FlxG.sound.play(Paths.sound('confirmMenu'));

			choseOption();
		}

		super.update(elapsed);
	}

	inline function changeSelection(change:Int)
	{
		texts.members[curSelected].alpha = 0.6;

		curSelected = FlxMath.wrap(curSelected + change, 0, texts.length - 1);
		texts.members[curSelected].alpha = 1;
	}

	function choseOption()
	{
		if (curSelected == 0)
		{
			CoolUtil.browserLoad("https://github.com/BernardoGP4504/FunkinVerade/releases");
			Sys.exit(0);
			return;
		}

		FlxFlicker.flicker(texts.members[curSelected], 1, 0.1, true, false, (_) -> FlxTimer.wait(0.5, () -> __getOut(0.2)));
	}

	inline function __getOut(hidingSpeed:Float)
	{
		FlxTween.tween(texts, {alpha: 0}, hidingSpeed, {onComplete: (_) -> 
			FlxG.switchState(initialState.toNextState())});
	}
}