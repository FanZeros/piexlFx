extends SceneTree

func _initialize():
    call_deferred("capture_all")

func capture_all():
    var specs = [
        ["Rivers/Rivers", "rivers"], ["DryTerran/DryTerran", "desert"],
        ["LandMasses/LandMasses", "earth"], ["NoAtmosphere/NoAtmosphere", "moon"],
        ["GasPlanet/GasPlanet", "gas"], ["GasPlanetLayers/GasPlanetLayers", "ringed"],
        ["IceWorld/IceWorld", "ice"], ["LavaWorld/LavaWorld", "lava"],
        ["Asteroids/Asteroid", "asteroid"], ["BlackHole/BlackHole", "black-hole"],
        ["Galaxy/Galaxy", "galaxy"], ["Star/Star", "star"]
    ]
    for spec in specs:
        if not spec[1] == "galaxy":
            continue
        var viewport = SubViewport.new()
        viewport.size = Vector2i(160, 160)
        viewport.transparent_bg = true
        viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
        root.add_child(viewport)
        var planet = load("res://Planets/" + spec[0] + ".tscn").instantiate()
        viewport.add_child(planet)
        planet.override_time = true
        var relative = planet.relative_scale
        var pixels = floor(150.0 / relative)
        planet.set_pixels(pixels)
        planet.set_anchors_preset(Control.PRESET_TOP_LEFT)
        planet.size = Vector2(pixels, pixels)
        planet.position = Vector2(80,80) - Vector2(pixels,pixels) * 0.5
        if spec[1] == "galaxy":
            var rect = planet.get_node("Galaxy")
            rect.set_anchors_preset(Control.PRESET_TOP_LEFT)
            rect.position = Vector2.ZERO
            rect.size = Vector2(pixels,pixels)
        var sheet = Image.create(1280,640,false,Image.FORMAT_RGBA8)
        for i in range(32):
            planet.set_custom_time(float(i) / 32.0)
            await process_frame
            await RenderingServer.frame_post_draw
            var image = viewport.get_texture().get_image()
            sheet.blit_rect(image,Rect2i(0,0,160,160),Vector2i((i%8)*160,(i/8)*160))
        var target = "/workspace/assets/Effects/planet-" + spec[1] + ".png"
        sheet.save_png(target)
        print("CAPTURED ", target)
        viewport.queue_free()
        await process_frame
    quit()
