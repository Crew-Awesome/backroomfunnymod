var hudScale:Float = 1;
var hudLeft:Float = 0;
var hudTop:Float = 0;
var hudMoved:Bool = false;

function hudLayout() {
    hudScale = Math.min(FlxG.width / 960, FlxG.height / 720);
    hudLeft = (FlxG.width - 960 * hudScale) * 0.5;
    hudTop = (FlxG.height - 720 * hudScale) * 0.5;
}

function hudMovePlayerLine(line:StrumLine) {
    if (line == null || line.members == null || line.members.length == 0) return;

    var maxX:Float = -100000;
    for (strum in line.members)
        if (strum != null) maxX = Math.max(maxX, strum.x + strum.width);

    if (maxX == -100000) return;

    var moveX = hudLeft + 960 * hudScale - 28 * hudScale - maxX;
    for (strum in line.members)
        if (strum != null) strum.x += moveX;
}

function hudApplyLayout() {
    hudLayout();

    var barX = hudLeft + 32 * hudScale;
    var barY = hudTop + 654 * hudScale;
    if (healthBarBG != null) {
        healthBarBG.x = barX;
        healthBarBG.y = barY;
        if (healthBar != null) {
            healthBar.x = barX + 4 * hudScale;
            healthBar.y = barY + 4 * hudScale;
        }
    }

    for (text in [scoreTxt, missesTxt, accuracyTxt]) {
        if (text == null) continue;
        text.x = barX + 4 * hudScale;
        text.y = barY - text.height - 6 * hudScale;
        if (healthBarBG != null) text.width = healthBarBG.width - 8 * hudScale;
    }
}

function postCreate() {
    hudLayout();
    for (line in strumLines.members) {
        if (line == null) continue;
        if (line.opponentSide) line.visible = false;
        else if (!hudMoved) hudMovePlayerLine(line);
    }
    hudMoved = true;
    hudApplyLayout();
}

function update(elapsed:Float) {
    hudApplyLayout();
}

function onResize(event) {
    hudApplyLayout();
}

function destroy() {
    hudMoved = false;
}
