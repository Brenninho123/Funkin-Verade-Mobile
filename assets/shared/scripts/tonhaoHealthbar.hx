import objects.Bar;

using StringTools;

var usingThisUI:Bool = false;
final strumOffset:Float = ((FlxG.width / 2) + 50);
var opponentHealthBar:Bar = null;

function onCreatePost()
{
	usingThisUI = (PlayState.stageUI == "normal" || PlayState.stageUI == "pixel");
	if (!usingThisUI) return;

	game.healthBar.x = PlayState.STRUM_X + strumOffset;
	game.healthBar.y -= 60;
	applyBarStuff(game.healthBar, true, [34, -5]);

	opponentHealthBar = new Bar(-game.healthBar.barWidth - 87, 0, 'healthBar', () -> game.healthBar.bounds.max - health, 0, 2);
	applyBarStuff(opponentHealthBar, false, [55, -5]);
	setBarColorRGB(opponentHealthBar, game.dad.healthColorArray);
	game.healthBar.add(opponentHealthBar);
	setVar('opponentHealthBar', opponentHealthBar);

	game.updateIconsPosition = function()
	{
		game.iconP1.x = game.healthBar.x + (strumOffset / 2);
		game.iconP2.x = (game.healthBar.x - strumOffset);
	};
}

function onEvent(n:String, v1:String)
{
	if (n != "Change Character") return;

	var charType:Int = switch(v1.toLowerCase().trim())
	{
		case 'gf', 'girlfriend': 2;
		case 'dad', 'opponent': 1;
		default: Std.parseInt(v1) ?? 0;
	};
	if (charType != 1) return;

	setBarColorRGB(opponentHealthBar, game.dad.healthColorArray);
}

function onUpdatePost()
{
	if (!usingThisUI) return;
	setBarColorRGB(game.healthBar, game.boyfriend.healthColorArray);

	if (FlxG.keys.justPressed.F5) FlxG.resetState(); // menos tortura sem ter menu de pause
}

function applyBarStuff(bar:Bar, isPlayerBar:Bool, barOffset:Array<Float>)
{
	bar.bg.scale.set(0.73, 0.73); bar.bg.updateHitbox();
	bar.bg.flipX = isPlayerBar;

	bar.barWidth = 552;
	for (b in [bar.leftBar, bar.rightBar])
	{
		b.loadGraphic(Paths.image('healthBar_bar'));
		b.antialiasing = true;
		b.offset.set(barOffset[0], barOffset[1]);
		b.flipX = isPlayerBar;
	}
	bar.barOffset.set(-2, -1);
	bar.leftToRight = true;
}

inline function setBarColorRGB(bar:Bar, colorRGB:Array<Int>)
{
	final color:FlxColor = FlxColor.fromRGB(colorRGB[0], colorRGB[1], colorRGB[2]);
	bar.setColors(color, FlxColor.BLACK);
}