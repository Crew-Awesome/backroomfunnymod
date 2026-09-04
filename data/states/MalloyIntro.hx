import flixel.text.FlxTextBorderStyle;
import funkin.backend.system.framerate.Framerate;

var introSkip:Dynamic = importScript("data/scripts/IntroSkip");
var titleLetters:Array<FunkinText> = [];
var titleBang:FunkinText;
var subtitle:FunkinText;
var titleAdvances:Array<Float> = [];
var introTitleY:Float = 0;
var introFinished:Bool = false;
var jingle:Dynamic;
var introCameraZoom:Float = 1;
var introCamera:FlxCamera;
var malloyTitleMoveAt:Float = 1.5064;
var malloyAudioBeatAt:Float = 1.7937;
var malloyOutroAt:Float = 3;
var malloyIntroStartDelay:Float = 0.08;
var malloyTitleMoveDuration:Float = 0.2873;
var malloyTitleShift:Float = -28;
var malloyTitlePadding:Float = 12;
var malloyRevealScale:Float = 0.85;

function startOutro() {
    if (introFinished) return;
    if (introSkip != null && introSkip.get("skipPending")) {
        new FlxTimer().start(0.1, function(_) startOutro());
        return;
    }
    introFinished = true;
    introCamera.fade(0xFF000000, 1.792857, false, function() {
        if (jingle != null) jingle.stop();
        FlxG.switchState(new funkin.backend.scripting.ModState("NezumiIntro"));
    }, true);
}

function setTitleStyle(text:FunkinText, size:Int, color:Int) {
    text.setFormat(Paths.font("FunkinOptions.otf"), size, color);
    text.borderStyle = FlxTextBorderStyle.OUTLINE;
    text.borderSize = 5;
    text.borderColor = 0xFFFFFFFF;
    text.scrollFactor.set();
    text.cameras = [introCamera];
}

function setupLetter(letter:FunkinText, rotation:Float, delay:Float, revealScale:Float) {
    letter.alpha = 0;
    letter.scale.set(0.55, 0.04);
    letter.origin.set(letter.width * 0.5, letter.height * 0.88);
    letter.angle = rotation * -0.35;
    add(letter);

    var phases:Array<Dynamic> = [
        {x: 1.12, y: 0.28, angle: rotation * -0.45, lift: 0, duration: 0.076, offset: 0, ease: FlxEase.quadOut},
        {x: 0.76, y: 1.38, angle: rotation * 1.25, lift: -18, duration: 0.182, offset: 0.076, ease: FlxEase.cubeOut},
        {x: 1.25, y: 0.74, angle: rotation * -0.8, lift: 0, duration: 0.152, offset: 0.258, ease: FlxEase.quadIn},
        {x: 0.90, y: 1.12, angle: rotation * 0.45, lift: -5, duration: 0.114, offset: 0.410, ease: FlxEase.quadOut},
        {x: 1.045, y: 0.96, angle: rotation * -0.18, lift: 0, duration: 0.106, offset: 0.524, ease: FlxEase.quadInOut},
        {x: 1, y: 1, angle: 0, lift: 0, duration: 0.122, offset: 0.630, ease: FlxEase.sineInOut}
    ];
    for (phase in phases)
        tweenLetter(letter, phase.x, phase.y, phase.angle, phase.lift,
            phase.duration * revealScale, delay + phase.offset * revealScale, phase.ease);
}

function padTitleLetter(letter:FunkinText, padding:Float):Float {
    letter.updateHitbox();
    var glyphWidth = letter.textField.textWidth;
    letter.fieldWidth = glyphWidth + padding * 2;
    letter.alignment = "center";
    letter.updateHitbox();
    return glyphWidth;
}

function tweenLetter(letter:FunkinText, scaleX:Float, scaleY:Float, angle:Float, lift:Float, duration:Float, delay:Float, ease:Dynamic) {
    FlxTween.tween(letter, {alpha: 1, angle: angle, y: introTitleY + lift}, duration, {ease: ease, startDelay: delay});
    FlxTween.tween(letter.scale, {x: scaleX, y: scaleY}, duration, {ease: ease, startDelay: delay});
}

function cameraBeatBounce() {
    FlxTween.tween(introCamera, {zoom: introCameraZoom * 1.10}, 0.14, {ease: FlxEase.sineInOut});
    FlxTween.tween(introCamera, {zoom: introCameraZoom}, 1.01, {ease: FlxEase.sineInOut, startDelay: 0.14});
}

function completeSkip() {
    if (introFinished) return;
    introFinished = true;
    if (jingle != null) jingle.stop();
    introCamera.fade(0xFF000000, 0.22, false, function() {
        FlxG.switchState(new funkin.backend.scripting.ModState("NezumiIntro"));
    }, true);
}

function malloyCreateTitle() {
    introTitleY = FlxG.height * 0.36;
    var word = "ImMalloy";
    var rotations = [-8, 6.4, -6.4, 8, -6.4, 6.4, -8, 6.4];
    var letterGap:Float = 8;
    var titleOffsetX:Float = -12;
    var totalWidth:Float = 0;

    for (i in 0...word.length) {
        var letter = new FunkinText(0, introTitleY, 0, word.charAt(i), 150);
        setTitleStyle(letter, 150, 0xFF5B8CFF);
        titleAdvances.push(padTitleLetter(letter, malloyTitlePadding));
        titleLetters.push(letter);
        totalWidth += titleAdvances[i] - letterGap;
    }

    var cursor = (FlxG.width - totalWidth) * 0.5 + titleOffsetX;
    var letterDelays = [0.0493, 0.2090, 0.3744, 0.5486, 0.7082, 0.8824, 1.0594, 1.2278];
    for (i => letter in titleLetters) {
        letter.x = cursor;
        letter.y = introTitleY;
        cursor += titleAdvances[i] - letterGap;
        setupLetter(letter, rotations[i], letterDelays[i] + malloyIntroStartDelay, malloyRevealScale);
    }

    titleBang = new FunkinText(cursor + malloyTitleShift, introTitleY, 0, "!", 150);
    setTitleStyle(titleBang, 150, 0xFF5B8CFF);
    padTitleLetter(titleBang, malloyTitlePadding);
    setupLetter(titleBang, 8, malloyTitleMoveAt + malloyIntroStartDelay, malloyRevealScale);
}

function malloyCreateSubtitle() {
    var subtitleY:Float = introTitleY + 133;
    subtitle = new FunkinText(0, subtitleY, 0, "Always Amazing!", 36);
    subtitle.setFormat(Paths.font("FunkinLingLong.otf"), 36, 0xFFFFFFFF);
    subtitle.scrollFactor.set();
    subtitle.cameras = [introCamera];
    subtitle.updateHitbox();
    subtitle.x = (FlxG.width - subtitle.width) * 0.5 + 90;
    subtitle.alpha = 0;
    subtitle.y -= 30;
    add(subtitle);
    FlxTween.tween(subtitle, {alpha: 0.72, y: subtitleY}, 0.45, {ease: FlxEase.quadOut, startDelay: 1.2278 + malloyIntroStartDelay});
}

function malloySchedule() {
    introSkip.call("setup", [function() completeSkip()]);

    var titleMoveDelay:Float = malloyTitleMoveAt + malloyIntroStartDelay;
    for (letter in titleLetters)
        FlxTween.tween(letter, {x: letter.x + malloyTitleShift}, malloyTitleMoveDuration, {ease: FlxEase.sineInOut, startDelay: titleMoveDelay});
    FlxTween.tween(subtitle, {x: subtitle.x + malloyTitleShift}, malloyTitleMoveDuration, {ease: FlxEase.sineInOut, startDelay: titleMoveDelay});

    new FlxTimer().start(malloyIntroStartDelay, function(_) {
        if (!introFinished) jingle = FlxG.sound.play(Paths.sound("malloyfatjingle", null, "ogg"));
    });
    new FlxTimer().start(malloyAudioBeatAt + malloyIntroStartDelay, function(_) cameraBeatBounce());
    new FlxTimer().start(malloyOutroAt + malloyIntroStartDelay, function(_) startOutro());
}

function create() {
    Framerate.debugMode = 0;
    if (FlxG.sound.music != null) FlxG.sound.music.stop();

    introCamera = new FlxCamera();
    introCamera.bgColor = 0xFF000000;
    FlxG.cameras.add(introCamera, false);

    var background = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
    background.scrollFactor.set();
    background.cameras = [introCamera];
    add(background);
    FlxG.mouse.visible = true;
    introCameraZoom = introCamera.zoom * 1.06;
    introCamera.zoom = introCameraZoom;

    malloyCreateTitle();
    malloyCreateSubtitle();
    malloySchedule();
}

function destroy() {
    if (jingle != null) jingle.stop();
    if (introCamera != null && FlxG.cameras.list.contains(introCamera)) FlxG.cameras.remove(introCamera);
    titleLetters = [];
    titleAdvances = [];
    titleBang = null;
    subtitle = null;
    introCamera = null;
    introSkip = null;
    jingle = null;
    introFinished = false;
    introCameraZoom = 1;
}
