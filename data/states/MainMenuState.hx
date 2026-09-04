import flixel.text.FlxTextBorderStyle;
import funkin.backend.system.framerate.Framerate;
import foxlite.loaders.FoxGLTFLoader;
import foxlite.lights.FoxPointLight;
import foxlite.texture.FoxMipFilter;

var menuRevealSkip:Dynamic = importScript("data/scripts/IntroSkip");
var menuScene:FoxScene;
var menuCamera:FoxCamera;
var menuRoot:Dynamic;
var menuBulbA:FoxPointLight;
var menuBulbB:FoxPointLight;
var menuCharacterLight:FoxPointLight;
var menuItems3D:Array<FlxText> = [];
var menuTitle:FlxText;
var menuCreditsRows:Array<Dynamic> = [];
var menuLoadBackdrop:FlxSprite;
var menuOverlay:FlxSprite;
var menuMaterials:Dynamic;
var menuSelected:Int = 0;
var menuTime:Float = 0;
var menuReady:Bool = false;
var menuRevealStarted:Bool = false;
var menuScale:Float = 1;
var menuLeft:Float = 0;
var menuTop:Float = 0;
var menuCreditsVisible:Bool = false;
var menuCreditsWaitForRelease:Bool = false;
var menuCreditsTransitioning:Bool = false;
var menuUiRevealStarted:Bool = false;
var menuRevealWaitForRelease:Bool = false;
var menuLabels:Array<String> = ["PLAY", "CREDITS", "OPTIONS"];
var menuDesignWidth:Float = 960;
var menuDesignHeight:Float = 720;
var menuItemStartY:Float = 250;
var menuItemStepY:Float = 68;
var menuEdgeInset:Float = 56;
var menuCredits:Array<Dynamic> = [
    {label: "CREDITS", font: "DMSans-Medium.ttf", x: 480, y: 165, width: 620},
    {label: "DIRECTORS", font: "DMSans-Medium.ttf", x: 240, y: 245, width: 260},
    {label: "ImMalloy", font: "DMSans-Light.ttf", x: 240, y: 285, width: 260},
    {label: "Nezumieepy", font: "DMSans-Light.ttf", x: 240, y: 317, width: 260},
    {label: "COMPOSERS", font: "DMSans-Medium.ttf", x: 480, y: 245, width: 260},
    {label: "BumbleBea", font: "DMSans-Light.ttf", x: 480, y: 285, width: 260},
    {label: "CHARTERS", font: "DMSans-Medium.ttf", x: 720, y: 245, width: 260},
    {label: "Neon", font: "DMSans-Light.ttf", x: 720, y: 285, width: 260},
    {label: "3D BG MODEL", font: "DMSans-Medium.ttf", x: 720, y: 345, width: 260},
    {label: "Gregsterius", font: "DMSans-Light.ttf", x: 720, y: 385, width: 260}
];

function menuLayout() {

    menuScale = Math.min(FlxG.width / menuDesignWidth, FlxG.height / menuDesignHeight);
    menuLeft = (FlxG.width - menuDesignWidth * menuScale) * 0.5;
    menuTop = (FlxG.height - menuDesignHeight * menuScale) * 0.5;

    for (i => item in menuItems3D) {
        item.scale.set(menuScale, menuScale);
        item.updateHitbox();
        item.x = menuLeft + menuEdgeInset * menuScale;
        item.y = menuTop + (menuItemStartY + i * menuItemStepY) * menuScale;
    }

    if (menuTitle != null) {
        menuTitle.scale.set(menuScale, menuScale);
        menuTitle.updateHitbox();
        menuTitle.x = menuLeft + menuDesignWidth * menuScale - menuEdgeInset * menuScale - menuTitle.width;
        menuTitle.y = menuTop + 32 * menuScale;
    }

    for (credit in menuCreditsRows) {
        var row:FlxText = credit.text;
        row.scale.set(menuScale, menuScale);
        row.updateHitbox();
        row.x = menuLeft + credit.x * menuScale - row.width * 0.5;
        row.y = menuTop + credit.y * menuScale;
    }

}

function menuRefresh() {
    for (i => item in menuItems3D) {
        item.color = i == menuSelected ? 0xFFFFD49A : 0xFFFFFFFF;
        item.alpha = menuReady ? (i == menuSelected ? 1 : 0.65) : 0;
    }
}

function menuTweenItems(duration:Float, startDelay:Float = 0, stagger:Float = 0) {
    for (i => item in menuItems3D)
        FlxTween.tween(item, {alpha: i == menuSelected ? 1 : 0.65}, duration, {
            ease: FlxEase.quadOut,
            startDelay: startDelay + i * stagger
        });
}

function menuShowUi() {
    if (menuUiRevealStarted) return;
    menuUiRevealStarted = true;
    if (menuRevealSkip != null) menuRevealSkip.call("setEnabled", [false]);
    FlxTween.tween(menuOverlay, {alpha: 1}, 0.3, {ease: FlxEase.quadOut});
    FlxTween.tween(menuTitle, {alpha: 1}, 0.35, {ease: FlxEase.quadOut, startDelay: 0.2});

    menuTweenItems(0.35, 0.4, 0.08);

    for (i => item in menuItems3D)
        FlxTween.flicker(item, 0.35, 0.06, {
            startDelay: 0.4 + i * 0.08,
            endVisibility: true,
            ratio: 0.65
        });

    new FlxTimer().start(0.95, function(_) {
        menuReady = true;
        menuRefresh();
    });
}

function menuSkipFall() {
    if (!menuRevealStarted || menuUiRevealStarted || menuCamera == null) return;
    menuRevealWaitForRelease = true;
    FlxTween.cancelTweensOf(menuLoadBackdrop);
    FlxTween.cancelTweensOf(menuCamera);
    menuLoadBackdrop.alpha = 0;
    menuCamera.y = 1.3;
    menuShowUi();
}

function openCredits() {
    if (menuCreditsVisible || menuCreditsTransitioning) return;
    menuCreditsVisible = true;
    menuCreditsWaitForRelease = true;
    menuCreditsTransitioning = true;
    for (item in menuItems3D)
        FlxTween.tween(item, {alpha: 0}, 0.2, {ease: FlxEase.quadIn});
    FlxTween.tween(menuTitle, {alpha: 0}, 0.2, {
        ease: FlxEase.quadIn,
        onComplete: function(_) {
            for (credit in menuCreditsRows)
                FlxTween.tween(credit.text, {alpha: 1}, 0.35, {ease: FlxEase.quadOut});
            new FlxTimer().start(0.35, function(_) menuCreditsTransitioning = false);
        }
    });
}

function closeCredits() {
    if (!menuCreditsVisible || menuCreditsTransitioning) return;
    menuCreditsVisible = false;
    menuCreditsWaitForRelease = true;
    menuCreditsTransitioning = true;
    for (credit in menuCreditsRows)
        FlxTween.tween(credit.text, {alpha: 0}, 0.2, {ease: FlxEase.quadIn});
    new FlxTimer().start(0.2, function(_) {
        FlxTween.tween(menuTitle, {alpha: 1}, 0.3, {
            ease: FlxEase.quadOut,
            onComplete: function(_) menuCreditsTransitioning = false
        });
        menuTweenItems(0.3);
    });
}

function menuMouseOver(item:FlxText):Bool {
    var mouse = FlxG.mouse.getPosition();
    return item.overlapsPoint(mouse, true);
}

function flickerEnergy(time:Float, phase:Float, energy:Float):Float {
    var cutsOut = Math.sin(time * 11 + phase) > 0.72 || Math.sin(time * 37 + phase * 1.7) > 0.9;
    return cutsOut ? 0 : energy;
}

function menuTexturesReady():Bool {
    if (menuRoot == null || menuMaterials == null) return false;

    for (material in menuMaterials) {
        if (material == null || material.textures == null) continue;
        for (texture in material.textures)
            if (texture != null && texture.glTexture == null) return false;
    }
    return true;
}

function menuStartReveal() {
    if (menuRevealStarted || menuCamera == null) return;
    menuRevealStarted = true;
    if (menuRevealSkip != null) menuRevealSkip.call("setEnabled", [true]);
    FlxTween.tween(menuLoadBackdrop, {alpha: 0}, 0.6, {ease: FlxEase.sineInOut});
    FlxTween.tween(menuCamera, {y: 1.3}, 3.4, {
        ease: FlxEase.sineInOut,
        onComplete: function(_) menuShowUi()
    });
}

function create() {
    Framerate.debugMode = 0;
}

function menuCreateBackdrop() {
    menuLoadBackdrop = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
    menuLoadBackdrop.scrollFactor.set();
    menuLoadBackdrop.cameras = [FlxG.camera];
    add(menuLoadBackdrop);

    menuOverlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0x99000000);
    menuOverlay.alpha = 0;
    menuOverlay.scrollFactor.set();
    menuOverlay.cameras = [FlxG.camera];
    add(menuOverlay);
}

function menuCreateTitle() {
    menuTitle = new FlxText(0, 0, 400, "BACKROOM", 34);
    menuTitle.setFormat(Paths.font("DMSans-Medium.ttf"), 34, 0xFFFFFFFF);
    menuTitle.alpha = 0;
    menuTitle.alignment = "right";
    menuTitle.borderStyle = FlxTextBorderStyle.OUTLINE;
    menuTitle.borderColor = 0xFF000000;
    menuTitle.scrollFactor.set();
    menuTitle.cameras = [FlxG.camera];
    add(menuTitle);
}

function menuCreateCredits() {
    for (credit in menuCredits) {
        var row = new FlxText(0, 0, credit.width, credit.label, 30);
        row.setFormat(Paths.font(credit.font), 30, 0xFFFFFFFF);
        row.alignment = "center";
        row.borderStyle = FlxTextBorderStyle.OUTLINE;
        row.borderColor = 0xFF000000;
        row.alpha = 0;
        row.scrollFactor.set();
        row.cameras = [FlxG.camera];
        menuCreditsRows.push({text: row, x: credit.x, y: credit.y});
        add(row);
    }
}

function menuCreateItems() {
    for (label in menuLabels) {
        var item = new FlxText(0, 0, 360, label, 32);
        item.setFormat(Paths.font("DMSans-Light.ttf"), 32, 0xFFFFFFFF);
        item.ID = menuItems3D.length;
        item.borderStyle = FlxTextBorderStyle.OUTLINE;
        item.borderColor = 0xFF000000;
        item.scrollFactor.set();
        item.cameras = [FlxG.camera];
        menuItems3D.push(item);
        add(item);
    }
}

function menuCreateText() {
    if (bg != null) bg.visible = false;
    menuCreateBackdrop();
    menuCreateTitle();
    menuCreateCredits();
    menuCreateItems();
    menuLayout();
    menuRefresh();
}

function menuLoadModel(modelData:Dynamic):Bool {
    if (modelData == null || modelData.scenes == null || modelData.scenes.length == 0) return false;

    menuMaterials = modelData.materials ?? [];
    for (material in menuMaterials) {
        material.setScattering(0);
        for (texture in material.textures)
            if (texture != null) texture.mipFilter = FoxMipFilter.MIPNONE;
    }

    menuRoot = modelData.scenes[0];
    menuRoot.setScale(0.001, 0.001, 0.001);
    menuRoot.setPosition(0, 0, 0);
    menuScene.add(menuRoot);
    menuRoot.update(0);
    menuRoot.active = false;
    if (bg != null) bg.visible = false;
    return true;
}

function menuCreateSceneLights() {
    menuCamera = new FoxCamera(0, 5.5, 4.5, 0xFF000000);
    menuCamera.fov = 60;
    menuCamera.far = 125;
    menuScene.foxCameras.push(menuCamera);

    var sun = new FoxDirectionalLight(0, 0.5, 0.5, 0xFFFFFFFF, 0.14, false);
    sun.setAngle(-35, -25, 0);
    menuScene.add(sun);

    menuBulbA = new FoxPointLight(5.4375, 3.8125, -1.1125, 0xFFFFD49A, 1.8, 1.25, 1.2, false);
    menuBulbB = new FoxPointLight(5.625, 4.675, 3.675, 0xFFFFD49A, 1.8, 1.25, 1.2, false);
    menuCharacterLight = new FoxPointLight(0, 2.875, 0.5, 0xFFFFE6B8, 1.55, 3.5, 1.5, false);
    menuScene.add(menuBulbA);
    menuScene.add(menuBulbB);
    menuScene.add(menuCharacterLight);
}

function menuLoadScene() {
    if (menuScene != null) return;

    if (!FoxRenderer.initialized)
        FoxRenderer.initLibs();

    FoxLoaderUtil.initPathClass(Paths);
    menuScene = new FoxScene(FlxG.width, FlxG.height);
    menuScene.scrollFactor.set();
    menuScene.cameras = [FlxG.camera];
    menuScene.environment.ambientLight = 0xFF08090D;

    var modelData:Dynamic = FoxGLTFLoader.loadBinary("models/new-york_backstreet.glb", [], FoxShader.BASIC);
    if (!menuLoadModel(modelData))
        trace("Backroom menu: could not load models/new-york_backstreet.glb");

    menuCreateSceneLights();
    insert(0, menuScene);
}

function postCreate() {
    if (magenta != null) magenta.visible = false;
    if (menuItems != null) menuItems.visible = false;
    if (versionText != null) versionText.visible = false;
    if (devModeWarning != null) devModeWarning.visible = false;
    forceCenterX = false;
    selectedSomethin = true;
    menuCreateText();
    if (menuRevealSkip != null) {
        menuRevealSkip.call("setup", [function() menuSkipFall()]);
        menuRevealSkip.call("setEnabled", [false]);
    }

    new FlxTimer().start(0.05, function(_) menuLoadScene());
}

function menuUpdateLights() {
    if (menuBulbA != null) menuBulbA.energy = flickerEnergy(menuTime, 0, 1.8);
    if (menuBulbB != null) menuBulbB.energy = flickerEnergy(menuTime, 1.4, 1.8);
    if (menuCharacterLight != null) menuCharacterLight.energy = flickerEnergy(menuTime, 2.8, 1.55);
}

function menuHandleDebug():Bool {
    if (canAccessDebugMenus && controls.DEV_ACCESS) {
        persistentUpdate = false;
        persistentDraw = true;
        openSubState(new funkin.editors.EditorPicker());
        return true;
    }

    if (!Options.devMode && FlxG.keys.justPressed.SEVEN) {
        FlxG.sound.play(Paths.sound(Flags.DEFAULT_EDITOR_DELETE_SOUND));
        if (devModeCount++ == 2) {
            devModeWarning.visible = true;
            FlxTween.tween(devModeWarning, {alpha: 1}, 0.4);
        }
        FlxTween.completeTweensOf(devModeWarning);
        FlxTween.color(devModeWarning, 0.2, 0xFFFF0000, 0xFFFFFFFF);
        FlxTween.shake(devModeWarning, 0.005, 0.3);
        devModeWarning.y = FlxG.height - 75;
        FlxTween.tween(devModeWarning, {y: FlxG.height - 50}, 0.4);
    }
    return false;
}

function menuHandleModal():Bool {
    if (menuCreditsTransitioning) return true;

    if (menuRevealWaitForRelease) {
        if (!controls.ACCEPT && !FlxG.keys.pressed.ENTER && !controls.BACK && !FlxG.mouse.pressed)
            menuRevealWaitForRelease = false;
        return true;
    }

    if (menuCreditsWaitForRelease) {
        if (!controls.ACCEPT && !controls.BACK && !FlxG.mouse.pressed)
            menuCreditsWaitForRelease = false;
        return true;
    }

    if (menuCreditsVisible) {
        if (controls.BACK || controls.ACCEPT || FlxG.mouse.justPressed)
            closeCredits();
        return true;
    }
    return false;
}

function menuHandleSelection() {
    var hovered = -1;
    for (i => item in menuItems3D)
        if (menuMouseOver(item)) hovered = i;

    if (hovered >= 0 && hovered != menuSelected) {
        menuSelected = hovered;
        menuRefresh();
    }

    var change = (controls.UP_P ? -1 : 0) + (controls.DOWN_P ? 1 : 0);
    if (change != 0) {
        menuSelected = FlxMath.wrap(menuSelected + change, 0, menuItems3D.length - 1);
        menuRefresh();
    }

    if (controls.ACCEPT || (FlxG.mouse.justPressed && hovered >= 0)) {
        switch (menuSelected) {
            case 0: FlxG.switchState(new FreeplayState());
            case 1: openCredits();
            case 2: FlxG.switchState(new funkin.options.OptionsMenu());
        }
    }

    if (controls.BACK)
        FlxG.switchState(new TitleState());
}

function update(elapsed:Float) {
    menuTime += elapsed;
    menuUpdateLights();

    if (!menuRevealStarted && menuTexturesReady()) menuStartReveal();
    if (!menuReady) return;
    if (menuHandleDebug()) return;

    if (controls.SWITCHMOD) {
        openSubState(new funkin.menus.ModSwitchMenu());
        persistentUpdate = false;
        persistentDraw = true;
        return;
    }

    if (menuHandleModal()) return;
    menuHandleSelection();
}

function onResize(event) {
    menuLayout();
    if (menuScene != null) menuScene.setupBuffers(FlxG.width, FlxG.height);
}

function destroy() {
    if (menuScene != null) {
        remove(menuScene, true);
        menuScene.destroy();
        menuScene = null;
    }
    menuItems3D = [];
    menuTitle = null;
    menuCreditsRows = [];
    menuLoadBackdrop = null;
    menuOverlay = null;
    menuMaterials = null;
    menuSelected = 0;
    menuTime = 0;
    menuReady = false;
    menuRevealStarted = false;
    menuCreditsVisible = false;
    menuCreditsWaitForRelease = false;
    menuCreditsTransitioning = false;
    menuUiRevealStarted = false;
    menuRevealWaitForRelease = false;
}
