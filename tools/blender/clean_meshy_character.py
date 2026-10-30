# Blender headless cleanup for the Meshy wolf model before importing into Roblox.
# Usage: blender -b --factory-startup --python tools/blender/clean_meshy_character.py -- <input.glb> <output.glb>
import sys
import math
import bmesh
import bpy

argv = sys.argv[sys.argv.index("--") + 1:]
src_path, out_path = argv[0], argv[1]

MERGE_DISTANCE = 0.0005      # metres; welds duplicated seam vertices
SMOOTH_ANGLE = math.radians(50)
SMALL_HOLE_SIDES = 40        # only fill holes up to this many edges (palm hole), never big openings
BAKE_SIZE = 2048
BAKE_MARGIN = 24             # pixels of padding around UV islands
MAX_TRIS = 19800


def log(*parts):
    print("[clean]", *parts, flush=True)


def mesh_stats(obj):
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    tris = sum(len(f.verts) - 2 for f in bm.faces)
    boundary = sum(1 for e in bm.edges if e.is_boundary)
    stats = dict(verts=len(bm.verts), faces=len(bm.faces), tris=tris, boundary_edges=boundary)
    bm.free()
    return stats


bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src_path)

meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
log("mesh objects:", [(o.name, len(o.data.polygons)) for o in meshes])
if len(meshes) > 1:
    bpy.ops.object.select_all(action="DESELECT")
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.join()
obj = bpy.context.view_layer.objects.active or meshes[0]
bpy.context.view_layer.objects.active = obj
obj.select_set(True)

# find the base color texture of the imported material
mat = obj.active_material
src_image = None
for node in mat.node_tree.nodes:
    if node.type == "TEX_IMAGE" and node.image:
        for link in node.outputs["Color"].links:
            if link.to_socket.name == "Base Color":
                src_image = node.image
log("material:", mat.name, "base color image:", src_image and (src_image.name, tuple(src_image.size)))
log("before:", mesh_stats(obj))

# --- geometry fixes ---
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.mesh.remove_doubles(threshold=MERGE_DISTANCE)
bpy.ops.mesh.select_all(action="DESELECT")
bpy.ops.mesh.select_non_manifold(extend=False, use_wire=False, use_boundary=True,
                                 use_multi_face=False, use_non_contiguous=False, use_verts=False)
bpy.ops.mesh.fill_holes(sides=SMALL_HOLE_SIDES)
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.mesh.normals_make_consistent(inside=False)
bpy.ops.object.mode_set(mode="OBJECT")
log("after weld/fill:", mesh_stats(obj))

stats = mesh_stats(obj)
if stats["tris"] > MAX_TRIS:
    mod = obj.modifiers.new("Decimate", "DECIMATE")
    mod.ratio = MAX_TRIS / stats["tris"]
    bpy.ops.object.modifier_apply(modifier=mod.name)
    log("decimated:", mesh_stats(obj))

bpy.ops.object.shade_smooth_by_angle(angle=SMOOTH_ANGLE)

# --- re-bake base color with padding (dilates UV island borders) ---
if src_image is not None:
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 1
    scene.render.bake.margin = BAKE_MARGIN
    scene.render.bake.margin_type = "EXTEND"

    baked = bpy.data.images.new("wolf_basecolor_padded", BAKE_SIZE, BAKE_SIZE, alpha=False)
    nt = mat.node_tree
    out_node = next(n for n in nt.nodes if n.type == "OUTPUT_MATERIAL")
    shader_link = out_node.inputs["Surface"].links[0]
    shader_out = shader_link.from_socket

    # temporary emission = original texture colour, so the bake copies it exactly
    src_tex = next(n for n in nt.nodes if n.type == "TEX_IMAGE" and n.image == src_image)
    emit = nt.nodes.new("ShaderNodeEmission")
    nt.links.new(src_tex.outputs["Color"], emit.inputs["Color"])
    nt.links.new(emit.outputs["Emission"], out_node.inputs["Surface"])

    target = nt.nodes.new("ShaderNodeTexImage")
    target.image = baked
    nt.nodes.active = target
    log("baking", BAKE_SIZE, "margin", BAKE_MARGIN, "...")
    bpy.ops.object.bake(type="EMIT", margin=BAKE_MARGIN)
    log("bake done")

    # restore the shader and use the padded image as base colour; drop other maps
    nt.links.new(shader_out, out_node.inputs["Surface"])
    nt.nodes.remove(emit)
    bsdf = shader_out.node
    for name in ("Normal", "Roughness", "Metallic"):
        sock = bsdf.inputs.get(name)
        if sock:
            for l in list(sock.links):
                nt.links.remove(l)
    bsdf.inputs["Roughness"].default_value = 0.9
    bsdf.inputs["Metallic"].default_value = 0.0
    nt.links.new(target.outputs["Color"], bsdf.inputs["Base Color"])
    baked.pack()

log("final:", mesh_stats(obj))
bpy.ops.export_scene.gltf(filepath=out_path, export_format="GLB", use_selection=False,
                          export_apply=True, export_image_format="AUTO")
log("exported", out_path)
