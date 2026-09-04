var skipCamera:FlxCamera;
var skipText:FlxText;
var skipFinish:Dynamic;
var skipPending:Bool = false;
var skipHeldTime:Float = 0;
var skipFinished:Bool = false;
var skipEnabled:Bool = true;

function setup(finish:Dynamic) {
    skipCamera = new FlxCamera();
    skipCamera.bgColor = 0x00000000;
    FlxG.cameras.add(skipCamera, false);
    skipFinish = finish;
    skipPending = false;
    skipFinished = false;
    skipEnabled = true;

    skipText = new FlxText(0, 0, 240, "Skipping...", 16);
    skipText.setFormat(Paths.font("DMSans-Light.ttf"), 16, 0xFFFFFFFF);
    skipText.alignment = "right";
    skipText.alpha = 0;
    skipText.scrollFactor.set();
    skipText.cameras = [skipCamera];
    skipText.x = FlxG.width - skipText.width - 28;
    skipText.y = FlxG.height - skipText.height - 24;
    add(skipText);
}

function setEnabled(enabled:Bool) {
    skipEnabled = enabled;
    if (!enabled && skipText != null) {
        skipPending = false;
        skipHeldTime = 0;
        FlxTween.cancelTweensOf(skipText);
        skipText.alpha = 0;
    }
}

function beginSkip() {
    if (!skipEnabled || skipPending || skipFinished || skipText == null) return;
    skipPending = true;
    skipHeldTime = 0;
    skipText.text = "Skipping.";
    FlxTween.tween(skipText, {alpha: 0.75}, 0.16, {ease: FlxEase.quadOut});
}

function cancelSkip() {
    skipPending = false;
    skipHeldTime = 0;
    FlxTween.cancelTweensOf(skipText);
    FlxTween.tween(skipText, {alpha: 0}, 0.16, {ease: FlxEase.quadIn});
}

function finishSkip() {
    if (!skipPending || skipFinished) return;
    skipPending = false;
    skipFinished = true;
    FlxTween.cancelTweensOf(skipText);
    FlxTween.tween(skipText, {alpha: 0}, 0.18, {
        ease: FlxEase.quadIn,
        onComplete: function(_) {
            if (skipFinish != null) skipFinish();
        }
    });
}

function update(elapsed:Float) {
    if (!skipEnabled || skipFinished || skipText == null) return;

    var holdingSkip = controls.ACCEPT || FlxG.keys.pressed.ENTER || FlxG.mouse.pressed;
    if (holdingSkip) {
        beginSkip();
        if (skipPending) {
            skipHeldTime += elapsed;
            if (skipHeldTime >= 0.24) skipText.text = "Skipping...";
            else if (skipHeldTime >= 0.12) skipText.text = "Skipping..";
            if (skipHeldTime >= 0.45) finishSkip();
        }
    } else if (skipPending) {
        cancelSkip();
    }
}

function destroy() {
    if (skipText != null) FlxTween.cancelTweensOf(skipText);
    if (skipCamera != null && FlxG.cameras.list.contains(skipCamera)) FlxG.cameras.remove(skipCamera);
    skipCamera = null;
    skipText = null;
    skipFinish = null;
}
