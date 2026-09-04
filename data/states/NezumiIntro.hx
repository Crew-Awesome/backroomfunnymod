import flixel.text.FlxTextBorderStyle;
import funkin.backend.system.framerate.Framerate;

var introSkip:Dynamic = importScript("data/scripts/IntroSkip");
var nezumiCamera:FlxCamera;
var nezumiOpen:FlxText;
var nezumiName:FlxText;
var nezumiEepy:FlxText;
var nezumiClose:FlxText;
var nezumiAudio:Dynamic;
var nezumiFinished:Bool = false;
var nezumiOpenAt:Float = 0.712;
var nezumiEepyAt:Float = 1.903;
var nezumiOutroAt:Float = 3.488667;
var nezumiFadeDuration:Float = 0.65;

function styleLogo(text:FlxText, font:String, size:Int) {
    text.setFormat(Paths.font(font), size, 0xFFFFFFFF);
    text.alignment = "center";
    text.borderStyle = FlxTextBorderStyle.OUTLINE;
    text.borderSize = 2;
    text.borderColor = 0xFF000000;
    text.scrollFactor.set();
    text.cameras = [nezumiCamera];
    text.alpha = 0;
    add(text);
}

function startOutro() {
    if (nezumiFinished) return;
    if (introSkip != null && introSkip.get("skipPending")) {
        new FlxTimer().start(0.1, function(_) startOutro());
        return;
    }
    nezumiFinished = true;
    for (text in [nezumiOpen, nezumiName, nezumiEepy, nezumiClose])
        FlxTween.tween(text, {alpha: 0}, nezumiFadeDuration, {ease: FlxEase.quadIn});
    nezumiCamera.fade(0xFF000000, nezumiFadeDuration, false, function() {
        if (nezumiAudio != null) nezumiAudio.stop();
        FlxG.switchState(new MainMenuState());
    }, true);
}

function completeSkip() {
    if (nezumiFinished) return;
    nezumiFinished = true;
    if (nezumiAudio != null) nezumiAudio.stop();
    nezumiCamera.fade(0xFF000000, 0.22, false, function() {
        FlxG.switchState(new MainMenuState());
    }, true);
}

function nezumiCreateTitle() {
    var titleY = FlxG.height * 0.40;
    var leftBracket = String.fromCharCode(0x300C);
    var rightBracket = String.fromCharCode(0x300D);
    nezumiOpen = new FlxText(0, titleY - 5, 0, leftBracket, 86);
    styleLogo(nezumiOpen, "NotoSansJP-Bold.ttf", 86);
    nezumiName = new FlxText(0, titleY, 0, "Nezumi", 82);
    styleLogo(nezumiName, "Helvetica Neue Condensed Bold.ttf", 82);
    nezumiEepy = new FlxText(0, titleY, 0, "eepy", 82);
    styleLogo(nezumiEepy, "Helvetica Neue Condensed Bold.ttf", 82);
    nezumiClose = new FlxText(0, titleY - 17, 0, rightBracket, 86);
    styleLogo(nezumiClose, "NotoSansJP-Bold.ttf", 86);

    for (text in [nezumiOpen, nezumiName, nezumiEepy, nezumiClose]) text.updateHitbox();
    var titleOverlap:Float = 4;
    var titleWidth = nezumiOpen.width + nezumiName.width + nezumiEepy.width + nezumiClose.width - titleOverlap * 3;
    var titleX = (FlxG.width - titleWidth) * 0.5;
    nezumiOpen.x = titleX;
    nezumiName.x = nezumiOpen.x + nezumiOpen.width - titleOverlap;
    nezumiEepy.x = nezumiName.x + nezumiName.width - titleOverlap;
    nezumiClose.x = nezumiEepy.x + nezumiEepy.width - 10;
}

function nezumiSchedule() {
    introSkip.call("setup", [function() completeSkip()]);

    nezumiAudio = FlxG.sound.play(Paths.sound("aslogoshit", null, "ogg"));
    new FlxTimer().start(nezumiOpenAt, function(_) {
        nezumiOpen.alpha = 1;
        nezumiName.alpha = 1;
    });
    new FlxTimer().start(nezumiEepyAt, function(_) {
        nezumiEepy.alpha = 1;
        nezumiClose.alpha = 1;
    });
    new FlxTimer().start(nezumiOutroAt, function(_) startOutro());
}

function create() {
    Framerate.debugMode = 0;
    if (FlxG.sound.music != null) FlxG.sound.music.stop();

    nezumiCamera = new FlxCamera();
    nezumiCamera.bgColor = 0xFF000000;
    FlxG.cameras.add(nezumiCamera, false);

    var background = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
    background.cameras = [nezumiCamera];
    add(background);

    nezumiCreateTitle();
    nezumiSchedule();
}

function destroy() {
    if (nezumiAudio != null) nezumiAudio.stop();
    if (nezumiCamera != null && FlxG.cameras.list.contains(nezumiCamera)) FlxG.cameras.remove(nezumiCamera);
    nezumiCamera = null;
    nezumiOpen = null;
    nezumiName = null;
    nezumiEepy = null;
    nezumiClose = null;
    nezumiAudio = null;
    introSkip = null;
    nezumiFinished = false;
}
