function setModAspectRatio() {
    if (Main.scaleMode != null && (FlxG.width != 960 || FlxG.height != 720)) {
        Main.scaleMode.width = 960;
        Main.scaleMode.height = 720;
    }
    if (window != null && !window.fullscreen) {
        window.resizable = false;
        if (window.width != 960) window.width = 960;
        if (window.height != 720) window.height = 720;
    }
}

function preStateCreate(state) {
    setModAspectRatio();
}

function postStateSwitch() {
    setModAspectRatio();
}
