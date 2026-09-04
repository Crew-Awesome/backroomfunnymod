import flixel.graphics.tile.FlxGraphicsShader;
import funkin.backend.system.framerate.Framerate;
import foxlite.loaders.FoxGLTFLoader;
import foxlite.lights.FoxPointLight;
import foxlite.texture.FoxMipFilter;

var scene:FoxScene;
var gameCamera:FoxCamera;
var dadCNECameraX:Float = 0;
var dadCNECameraY:Float = 0;
var bfCNECameraX:Float = 0;
var bfCNECameraY:Float = 0;
var cameraBaseGameZoom:Float = 1;
var cameraBaseZ:Float = 4.25;
var cameraTurn:Float = 0;
var stageRoot:Dynamic;
var cameraZoomTween:FlxTween;
var bulbLightA:FoxPointLight;
var bulbLightB:FoxPointLight;
var characterLight:FoxPointLight;
var dadSprite3D:FoxFunkinSprite;
var gfSprite3D:FoxFunkinSprite;
var bfSprite3D:FoxFunkinSprite;
var stageMaterials:Dynamic;
var stageLoadFade:FlxSprite;
var stageCharactersReady:Bool = false;
var stageLoadingReleased:Bool = false;
var hiddenStageProps:Array<String> = [
    "Cube.003_Wood ecectric stand_0",
    "Cylinder_Wood ecectric stand_0",
    "Cylinder.001_Blue metal_0",
    "Cube.048_Rusty metal_0",
    "Cube.006_One way_0",
    "Cylinder.002_Rusty metal_0",
    "Cylinder.003_Concret stairs_0"
];

function effectiveGameZoom():Float {
    var zoom = camGame != null ? camGame.zoom * camGame.zoomMultiplier : cameraBaseGameZoom;
    return zoom > 0 ? zoom : cameraBaseGameZoom;
}

function hideSourceSprite(sprite:Dynamic) {
    sprite.alpha = 1;
    sprite.colorTransform.alphaMultiplier = 0;
}

function sourceTextureReady(sprite:Dynamic):Bool {
    if (sprite == null || sprite.isAnimate != true) return sprite != null && sprite.pixels != null;
    var renderTexture = Reflect.field(sprite, "_renderTexture");
    var graphic = renderTexture == null ? null : Reflect.field(renderTexture, "graphic");
    return graphic != null && Reflect.field(graphic, "bitmap") != null;
}

function stageSpriteReady(source:Dynamic, billboard:Dynamic):Bool {
    if (!sourceTextureReady(source) || billboard == null || billboard.material == null) return false;
    var texture = billboard.material.textures.get("bitmap");
    return texture != null && texture.glTexture != null;
}

function stageTexturesReady():Bool {
    if (stageRoot == null || stageMaterials == null) return false;
    for (material in stageMaterials) {
        if (material == null || material.textures == null) continue;
        for (texture in material.textures)
            if (texture == null || texture.glTexture == null) return false;
    }
    return stageSpriteReady(dad, dadSprite3D)
        && stageSpriteReady(gf, gfSprite3D)
        && stageSpriteReady(bf, bfSprite3D);
}

function stageNode(name:String):Dynamic {
    var node = stageRoot.getFirstByName(name);
    if (node == null) stageRoot.forEach(function(candidate) {
        if (node == null && candidate.name == name) node = candidate;
    }, true);
    return node;
}

function stageLoadModel():Bool {
    var modelData:Dynamic = FoxGLTFLoader.loadBinary("models/new-york_backstreet.glb", [], FoxShader.BASIC);
    if (modelData == null || modelData.scenes == null || modelData.scenes.length == 0) return false;

    stageMaterials = modelData.materials ?? [];
    for (material in stageMaterials) {
        material.setScattering(0.04);
        for (texture in material.textures)
            if (texture != null) texture.mipFilter = FoxMipFilter.MIPNONE;
    }

    stageRoot = modelData.scenes[0];
    stageRoot.setScale(0.001, 0.001, 0.001);
    stageRoot.setPosition(0, 0, 0);
    scene.add(stageRoot);

    for (name in hiddenStageProps) {
        var node = stageNode(name);
        if (node != null) node.visible = false;
    }

    stageRoot.update(0);
    stageRoot.active = false;
    return true;
}

function stageCreateCamera() {
    gameCamera = new FoxCamera(curCameraTarget == 1 ? 1.875 : -1.875, curCameraTarget == 1 ? 1.0625 : 1.8125, cameraBaseZ, 0xFF20242B);
    gameCamera.fov = 70;
    gameCamera.far = 125;
    scene.foxCameras.push(gameCamera);
}

function stageCreateLights() {
    var sun = new FoxDirectionalLight(0, 0.5, 0.5, 0xFFFFFFFF, 0.08, false);
    sun.setAngle(-35, -25, 0);
    scene.add(sun);

    bulbLightA = new FoxPointLight(5.4375, 3.8125, -1.1125, 0xFFFFD49A, 2.0, 1.25, 1.2, false);
    bulbLightB = new FoxPointLight(5.625, 4.675, 3.675, 0xFFFFD49A, 2.0, 1.25, 1.2, false);
    scene.add(bulbLightA);
    scene.add(bulbLightB);

    characterLight = new FoxPointLight(0, 2.875, 0.5, 0xFFFFE6B8, 1.8, 4.5, 1.5, false);
    scene.add(characterLight);
}

function create() {
    Framerate.debugMode = 0;
    if (!FoxRenderer.initialized)
        FoxRenderer.initLibs();

    FoxLoaderUtil.initPathClass(Paths);
    scene = new FoxScene(FlxG.width, FlxG.height);
    scene.scrollFactor.set();
    scene.cameras = [camHUD];
    scene.environment.ambientLight = 0xFF0C0F14;

    if (!stageLoadModel()) {
        trace("Backroom stage: could not load models/new-york_backstreet.glb");
        return;
    }

    stageCreateCamera();
    stageCreateLights();

    insert(0, scene);
}

function stageHoldSong() {
    stageLoadingReleased = false;
    if (PlayState.instance.startTimer != null)
        PlayState.instance.startTimer.cancel();
    PlayState.instance.startedCountdown = false;
}

function stageCreateLoadingFade() {
    stageLoadFade = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
    stageLoadFade.scrollFactor.set();
    stageLoadFade.cameras = [camHUD];
    add(stageLoadFade);
}

function stageCreateCharacters() {
    var billboardShader = FoxShader.fromAsset(FoxShader.BASIC, ["BILLBOARD_Y"]);
    cameraBaseGameZoom = effectiveGameZoom();

    if (gf.isAnimate) {
        gf.useRenderTexture = true;
        gf.shader = new FlxGraphicsShader();
    }
    for (animName in gf.animOffsets.keys()) {
        var animOffset = gf.animOffsets.get(animName);
        if (animOffset != null) animOffset.set(0, 0);
    }

    dadSprite3D = new FoxFunkinSprite(dad, billboardShader, 0.00125);
    gfSprite3D = new FoxFunkinSprite(gf, billboardShader, 0.00125);
    bfSprite3D = new FoxFunkinSprite(bf, billboardShader, 0.00125);

    var dadCamera = dad.getCameraPosition();
    var bfCamera = bf.getCameraPosition();
    dadCNECameraX = dadCamera.x;
    dadCNECameraY = dadCamera.y;
    bfCNECameraX = bfCamera.x;
    bfCNECameraY = bfCamera.y;

    dadSprite3D.setPosition(-1.875, 1.75, 0.5);
    gfSprite3D.setPosition(-0.625, 1.5625, -1.25);
    bfSprite3D.setPosition(1.875, 1.0625, 0.5);
    dadSprite3D.setScale(3, 3, 3);
    gfSprite3D.setScale(3, 3, 3);
    bfSprite3D.setScale(3, 3, 3);
    dadSprite3D.visible = false;
    gfSprite3D.visible = false;
    bfSprite3D.visible = false;

    scene.add(dadSprite3D);
    scene.add(gfSprite3D);
    scene.add(bfSprite3D);

    hideSourceSprite(dad);
    hideSourceSprite(gf);
    hideSourceSprite(bf);
}

function postCreate() {
    stageHoldSong();
    stageCreateLoadingFade();
    stageCreateCharacters();
}

function syncCamera(elapsed:Float) {
    if (gameCamera == null || scene == null) return;

    scene.setupBuffers(FlxG.width, FlxG.height);
    var isBF = curCameraTarget == 1;
    var cameraCenterX = camGame != null ? camGame.scroll.x + camGame.width * 0.5 : dadCNECameraX;
    var cameraCenterY = camGame != null ? camGame.scroll.y + camGame.height * 0.5 : dadCNECameraY;
    var anchorX = isBF ? bfCNECameraX : dadCNECameraX;
    var anchorY = isBF ? bfCNECameraY : dadCNECameraY;
    var targetX = (isBF ? 1.875 : -1.875) + (cameraCenterX - anchorX) * 0.009375;
    var targetY = (isBF ? 1.0625 : 1.8125) - (cameraCenterY - anchorY) * 0.00125;
    var follow = Math.min(elapsed * 6, 1);
    gameCamera.position.x += (targetX - gameCamera.position.x) * follow;
    gameCamera.position.y += (targetY - gameCamera.position.y) * follow;
    if (cameraZoomTween == null)
        gameCamera.position.z = cameraBaseGameZoom > 0 ? cameraBaseZ * cameraBaseGameZoom / effectiveGameZoom() : cameraBaseZ;
    var targetTurn = isBF ? 0.06 : -0.06;
    cameraTurn += (targetTurn - cameraTurn) * Math.min(elapsed * 5, 1);
    gameCamera.setRotation(0, cameraTurn, 0);

    gameCamera.scene = scene;
    gameCamera.update(0);
}

function stageCancelCameraTween() {
    if (cameraZoomTween != null) cameraZoomTween.cancel();
    cameraZoomTween = null;
}

function stageApplyCameraZoom(chartEvent:Dynamic) {
    if (chartEvent.name == "Camera Zoom" && chartEvent.params[0] == true
        && chartEvent.params[4] != "CLASSIC" && chartEvent.params[4] != "linear"
        && chartEvent.params[5] == null)
        chartEvent.params[5] = "Out";

    if (chartEvent.params[2] == "camHUD") return;

    if (chartEvent.params[4] == "CLASSIC") {
        stageCancelCameraTween();
        return;
    }

    var newZoom = chartEvent.params[1] * (chartEvent.params[6] == "direct" ? FlxCamera.defaultZoom : stage.defaultZoom);
    if (chartEvent.params[7] == true) newZoom *= camGame.zoom;
    newZoom *= camGame.zoomMultiplier;
    var targetZ = cameraBaseZ * cameraBaseGameZoom / newZoom;
    stageCancelCameraTween();

    if (chartEvent.params[0] != true) {
        gameCamera.position.z = targetZ;
        cameraZoomTween = null;
        return;
    }

    var easeName = chartEvent.params[4] == "linear" ? "linear"
        : chartEvent.params[4] + (chartEvent.params[5] == null ? "Out" : chartEvent.params[5]);
    var ease = Reflect.field(FlxEase, easeName) ?? FlxEase.linear;
    var duration = (Conductor.stepCrochet / 1000) * (chartEvent.params[3] == null ? 4 : chartEvent.params[3]);
    trace('[Backroom Camera exact] Camera Zoom t=${Conductor.songPosition} current=${camGame.zoom} multiplier=${camGame.zoomMultiplier} raw=${chartEvent.params[1]} mode=${chartEvent.params[6]} suffix=${chartEvent.params[5]} ease=${easeName} duration=${duration} targetZ=${targetZ}');
    cameraZoomTween = FlxTween.tween(gameCamera.position, {z: targetZ}, duration, {
        ease: ease,
        onComplete: function(_) cameraZoomTween = null
    });
}

function onEvent(event) {
    if (event == null || event.event == null) return;
    var chartEvent = event.event;
    if (chartEvent.name == "Add Camera Zoom" || chartEvent.name == "Camera Bop") {
        stageCancelCameraTween();
        return;
    }
    if (chartEvent.name == "Camera Zoom") stageApplyCameraZoom(chartEvent);
}

function postUpdate(elapsed:Float) {
    if (!stageCharactersReady) {
        stageCharactersReady = stageTexturesReady();
        if (stageCharactersReady) {
            dadSprite3D.visible = true;
            gfSprite3D.visible = true;
            bfSprite3D.visible = true;
        } else return;
    }
    if (!stageLoadingReleased) {
        stageReleaseLoading();
    }
    syncCamera(elapsed);
}

function stageReleaseLoading() {
    stageLoadingReleased = true;
    PlayState.instance.startCountdown();
    FlxTween.tween(stageLoadFade, {alpha: 0}, 0.35, {
        ease: FlxEase.quadOut,
        onComplete: function(_) {
            remove(stageLoadFade, true);
            stageLoadFade = null;
        }
    });
}

function update(elapsed:Float) {
    if (!stageLoadingReleased) {
        if (PlayState.instance.startTimer != null)
            PlayState.instance.startTimer.active = false;
        PlayState.instance.startedCountdown = false;
    }
}

function destroy() {
    if (cameraZoomTween != null) cameraZoomTween.cancel();
    if (stageLoadFade != null) remove(stageLoadFade, true);
    if (scene == null) return;
    remove(scene);
    scene.destroy();
    scene = null;
    dadSprite3D = null;
    gfSprite3D = null;
    bfSprite3D = null;
    stageMaterials = null;
    stageLoadFade = null;
    stageCharactersReady = false;
    stageLoadingReleased = false;
    cameraTurn = 0;
}
