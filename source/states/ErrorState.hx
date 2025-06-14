package states;

class ErrorState extends FlxTransitionableState
{
	public var acceptCallback:Void->Void;
	public var backCallback:Void->Void;
	public var errorMsg:String;

	public function new(error:String, accept:Void->Void = null, back:Void->Void = null)
	{
		this.errorMsg = error;
		this.acceptCallback = accept;
		this.backCallback = back;

		super();
	}

	public var alphaSine(default, set):Float = 0;
	private inline function set_alphaSine(s)
	{
		if (alphaSine == s) return alphaSine;

		errorText.alpha = 1 - Math.sin((Math.PI * s) / 180);
		return alphaSine = s;
	}

	public var errorText:FlxText;

	override function create()
	{
		super.create();

		var bg = new FlxSprite(0, 0, Paths.image('menuBG'));
		bg.color = FlxColor.GRAY;
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.active = false;
		add(bg);

		errorText = new FlxText(0, 0, FlxG.width - 300, errorMsg, 32);
		errorText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		errorText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		errorText.screenCenter();
		errorText.active = false;
		add(errorText);
	}

	override function update(elapsed:Float)
	{
		if (Controls.instance.ACCEPT && acceptCallback != null) acceptCallback();
		if (Controls.instance.BACK && backCallback != null) backCallback();

		alphaSine += 180 * elapsed;
		super.update(elapsed);
	}
}