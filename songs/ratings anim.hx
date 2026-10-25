import flixel.text.FlxTextAlign;
import flixel.text.FlxTextBorderStyle;

var comboText = new FlxText(FlxG.height, FlxG.height / 1.5, 265, "hi", 64);

function postCreate(){
	minDigitDisplay = 0;
    comboGroup.maxSize = 1;
    comboGroup.visible = true;
    comboGroup.cameras = [camHUD];
    comboGroup.x = FlxG.height / 1.17;


    comboText.cameras = [camHUD];
    comboText.scale.x = 0;
    comboText.font = Paths.font("PositionsByArixbored-Regular .otf");
    comboText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 4);
    add(comboText);
}

function update(){
	comboText.text = combo;
}

function onPostRatingsShown(){
    comboGroup.y = 15 + FlxG.height / 2;
    comboGroup.alpha = 1;

    comboText.scale.x = 1;
    comboText.scale.y = 1;
    comboText.alignment = FlxTextAlign.CENTER;
    comboText.y = FlxG.height / 1.5;
    comboText.x = comboGroup.members[0].x;
    	
    FlxTween.cancelTweensOf(comboGroup);
	FlxTween.tween(comboGroup, {y: comboGroup.y - 15}, 0.2, {ease: FlxEase.cubeOut});
	FlxTween.tween(comboGroup, {alpha: 0}, 1, {ease: FlxEase.expoIn});

	FlxTween.cancelTweensOf(comboText.scale);
	FlxTween.cancelTweensOf(comboText);
	FlxTween.tween(comboText, {y: comboText.y - 15}, 0.2, {ease: FlxEase.cubeOut});
	FlxTween.tween(comboText.scale, {y: 2, x: 0}, 1, {ease: FlxEase.expoIn});

    comboGroup.forEachAlive(function(rating){
        FlxTween.cancelTweensOf(rating);
        rating.velocity.y = rating.velocity.x = rating.acceleration.y = 0;
    });
}
