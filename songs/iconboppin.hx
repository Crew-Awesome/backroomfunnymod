function create(){
doIconBop = false;
player.cpu = false;
}

function beatHit(){
iconP1.origin.set(iconP1.width * 0.25 , iconP1.height * 0.5);
iconP2.origin.set(iconP2.width * 0.75 + (26), iconP2.height * 0.5);
}

function update(elapsed){
    iconP1.scale.x = iconP1.scale.y = iconP2.scale.x = iconP2.scale.y = 
    FlxMath.lerp(1.15,1,FlxEase.cubeOut(Conductor.curBeatFloat - Conductor.curBeat));
}
