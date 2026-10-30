# Renders front/back previews of a GLB. Usage: blender -b --python tools/blender/preview_glb.py -- <in.glb> <out_prefix>
import sys
import math
import bpy
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
src, prefix = argv[0], argv[1]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
objs = [o for o in bpy.context.scene.objects if o.type == "MESH"]
mins = Vector((min(v[0] for o in objs for v in o.bound_box), min(v[1] for o in objs for v in o.bound_box), min(v[2] for o in objs for v in o.bound_box)))
maxs = Vector((max(v[0] for o in objs for v in o.bound_box), max(v[1] for o in objs for v in o.bound_box), max(v[2] for o in objs for v in o.bound_box)))
world_pts = [o.matrix_world @ Vector(c) for o in objs for c in o.bound_box]
lo = Vector((min(p.x for p in world_pts), min(p.y for p in world_pts), min(p.z for p in world_pts)))
hi = Vector((max(p.x for p in world_pts), max(p.y for p in world_pts), max(p.z for p in world_pts)))
center = (lo + hi) / 2
height = hi.z - lo.z
head = Vector((center.x, center.y, lo.z + height * 0.82))

scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x = 900
scene.render.resolution_y = 900
world = bpy.data.worlds.new("w")
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[1].default_value = 1.0
scene.world = world
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
sun.data.energy = 3
sun.rotation_euler = (math.radians(50), 0, math.radians(30))
scene.collection.objects.link(sun)

cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
scene.collection.objects.link(cam)
scene.camera = cam


def shoot(name, direction, target, dist):
    cam.location = target + direction.normalized() * dist
    look = (target - cam.location).normalized()
    cam.rotation_euler = look.to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = f"{prefix}_{name}.png"
    bpy.ops.render.render(write_still=True)
    print("[preview] wrote", scene.render.filepath, flush=True)


# glTF imports with -Y as the model's front in Blender
shoot("front", Vector((0, -1, 0.1)), center, height * 1.6)
shoot("back", Vector((0, 1, 0.1)), center, height * 1.6)
shoot("head_back", Vector((0, 1, 0.15)), head, height * 0.6)
shoot("head_front", Vector((0, -1, 0.05)), head, height * 0.6)
