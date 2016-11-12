# Translating operators from/to Armory player
import bpy
import numpy
import armutils
try:
    import barmory
except ImportError:
    pass

def parse_operator(text):
    if text == None:
        return
    # Proof of concept..
    text = text.split(' ', 1)
    if len(text) > 1:
        text = text[1]
        cmd = text.split('|')
        # Reflect commands from Armory player in Blender
        if cmd[0] == '__arm':
            if cmd[1] == 'quit':
                bpy.ops.arm.space_stop('EXEC_DEFAULT')
            if cmd[1] == 'screen_full_area':
                for area in bpy.context.screen.areas:
                    if area.type == 'VIEW_ARMORY':
                        override = {'window': bpy.context.window, 'screen': bpy.context.screen, 'area': area, 'blend_data': bpy.context.blend_data, 'region': bpy.context.region}
                        bpy.ops.screen.screen_full_area(override)
                        break
            elif cmd[1] == 'setx':
                bpy.context.scene.objects[cmd[2]].location.x = float(cmd[3])
            elif cmd[1] == 'select':
                bpy.context.object.select = False
                bpy.context.scene.objects[cmd[2]].select = True
                bpy.context.scene.objects.active = bpy.context.scene.objects[cmd[2]]
            elif cmd[1] == 'render':
                data = numpy.fromfile(armutils.get_fp() + '/build/html5/render.bin', dtype=numpy.uint8)
                data = data.astype(float)
                data = numpy.divide(data, 255)
                image = bpy.data.images.new("Render Result", width=int(cmd[2]), height=int(cmd[3]))
                image.pixels = data
                return

def send_operator(op):
    # Try to translate operator directly to armory
    if armutils.with_chromium() and bpy.context.object != None:
        objname = bpy.context.object.name
        if op.name == 'Translate':
            vec = bpy.context.object.location
            js_source = 'var o = armory.Scene.active.getChild("' + objname + '"); o.transform.loc.set(' + str(vec[0]) + ', ' + str(vec[1]) + ', ' + str(vec[2]) + '); o.transform.dirty = true;'
            barmory.call_js(js_source)
            return True
        elif op.name == 'Resize':
            vec = bpy.context.object.scale
            js_source = 'var o = armory.Scene.active.getChild("' + objname + '"); o.transform.scale.set(' + str(vec[0]) + ', ' + str(vec[1]) + ', ' + str(vec[2]) + '); o.transform.dirty = true;'
            barmory.call_js(js_source)
            return True
        elif op.name == 'Rotate':
            vec = bpy.context.object.rotation_euler.to_quaternion()
            js_source = 'var o = armory.Scene.active.getChild("' + objname + '"); o.transform.rot.set(' + str(vec[1]) + ', ' + str(vec[2]) + ', ' + str(vec[3]) + ' ,' + str(vec[0]) + '); o.transform.dirty = true;'
            barmory.call_js(js_source)
            return True
    return False
