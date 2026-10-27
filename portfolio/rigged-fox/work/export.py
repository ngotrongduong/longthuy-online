# Export fox.blend -> fox.fbx (mesh + armature + Idle & Walk takes), fox_idle.fbx, fox_walk.fbx, fox.glb
import bpy, os
OUT = r"C:\Ai kiem tien\portfolio\rigged-fox"
bpy.ops.wm.open_mainfile(filepath=os.path.join(OUT, "fox.blend"))
arm = bpy.data.objects["FoxRig"]; fox = bpy.data.objects["Fox"]
for o in bpy.context.scene.objects: o.select_set(o in (arm, fox))
bpy.context.view_layer.objects.active = arm

def set_action(name):
    a = bpy.data.actions[name]
    arm.animation_data.action = a
    if getattr(arm.animation_data, "action_slot", None) is None and len(a.slots):
        arm.animation_data.action_slot = a.slots[0]
    sc = bpy.context.scene
    sc.frame_start, sc.frame_end = int(a.frame_range[0]), int(a.frame_range[1])

FBX = dict(use_selection=True, object_types={'ARMATURE', 'MESH'}, apply_unit_scale=True,
           apply_scale_options='FBX_SCALE_UNITS', axis_forward='-Z', axis_up='Y', bake_space_transform=True,
           use_mesh_modifiers=False, mesh_smooth_type='FACE', add_leaf_bones=False, primary_bone_axis='Y',
           secondary_bone_axis='X', armature_nodetype='NULL', use_armature_deform_only=False,
           bake_anim=True, bake_anim_use_nla_strips=False, bake_anim_force_startend_keying=True,
           bake_anim_simplify_factor=0.0, bake_anim_step=1.0, path_mode='COPY', embed_textures=True)

set_action("Idle")
bpy.ops.export_scene.fbx(filepath=os.path.join(OUT, "fox.fbx"), bake_anim_use_all_actions=True, **FBX)
for name in ("Idle", "Walk"):
    set_action(name)
    bpy.ops.export_scene.fbx(filepath=os.path.join(OUT, f"fox_{name.lower()}.fbx"), bake_anim_use_all_actions=False, **FBX)

set_action("Idle")
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "fox.glb"), export_format='GLB', use_selection=True,
                          export_yup=True, export_apply=False, export_skins=True, export_animations=True,
                          export_animation_mode='ACTIONS', export_force_sampling=True, export_frame_step=1,
                          export_influence_nb=4, export_all_influences=False, export_image_format='AUTO')
print("EXPORTED")
