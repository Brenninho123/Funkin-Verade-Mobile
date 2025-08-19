var usingThisUI:Bool = false;

function onCreatePost()
{
	usingThisUI = PlayState.stageUI == "legacy";
	if (!usingThisUI) return;

	game.healthBar.bg.loadGraphic(Paths.image('healthBar_old'));
	game.healthBar.y -= 88;
	game.healthBar.barHeight = 19;
	game.healthBar.barOffset.y = 81;

	game.healthBar.leftBar.flipX = true;
	game.healthBar.rightBar.flipX = true;
	game.healthBar.barWidth = (game.healthBar.bg.width / 2) - 20;

	var blackBG:FlxSprite = new FlxSprite(22, game.healthBar.barOffset.y).makeGraphic(game.healthBar.barWidth * 2, game.healthBar.barHeight, FlxColor.BLACK);
	blackBG.active = false;
	game.healthBar.insert(0, blackBG);

	game.updateIconsPosition = () -> 
	{
		game.iconP1.x = (game.healthBar.x + game.healthBar.barWidth);
		game.iconP1.y = game.healthBar.y + 21;

		game.iconP2.x = game.iconP1.x - (game.iconP2.frameWidth * 0.8);
		game.iconP2.y = game.iconP1.y;
	};
	game.iconP1.flipX = !game.iconP1.flipX;
	game.iconP2.flipX = !game.iconP2.flipX;
	
	game.healthBar.bg.antialiasing = true;
}

function onUpdatePost()
{
	if (!usingThisUI) return;

	game.healthBar.rightBar.x = (game.healthBar.x - 20);
	game.healthBar.leftBar.x = (game.healthBar.rightBar.x - game.healthBar.barWidth) - 5.5;
}