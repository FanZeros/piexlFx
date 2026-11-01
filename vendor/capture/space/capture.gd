extends SceneTree

func _initialize():
    call_deferred("capture_all")

func capture_all():
    for i in range(4):
        seed(4200+i)
        var viewport = Viewport.new()
        viewport.size = Vector2(320,200)
        viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
        root.add_child(viewport)
        var bg = load("res://BackgroundGenerator/BackgroundGenerator.tscn").instance()
        viewport.add_child(bg)
        bg.rect_size = Vector2(320,200)
        bg.generate_new()
        yield(create_timer(0.8),"timeout")
        yield(VisualServer,"frame_post_draw")
        var image = viewport.get_texture().get_data()
        image.flip_y()
        var target = "/workspace/assets/Effects/space-"+str(i)+".png"
        image.save_png(target)
        print("CAPTURED ",target)
        viewport.queue_free()
        yield(self,"idle_frame")
    quit()
