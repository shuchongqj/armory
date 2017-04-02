import os
import bpy
import arm.utils

parsed_nodes = []

# Generating node sources
def build_node_trees():
    os.chdir(arm.utils.get_fp())

    # Make sure package dir exists
    nodes_path = 'Sources/' + bpy.data.worlds['Arm'].arm_project_package.replace(".", "/") + "/node"
    if not os.path.exists(nodes_path):
        os.makedirs(nodes_path)
    
    # Export node scripts
    for node_group in bpy.data.node_groups:
        if node_group.bl_idname == 'ArmLogicTreeType': # Build only logic trees
            node_group.use_fake_user = True # Keep fake references for now
            build_node_tree(node_group)

def build_node_tree(node_group):
    global parsed_nodes
    parsed_nodes = []
    root_nodes = get_root_nodes(node_group)

    path = 'Sources/' + bpy.data.worlds['Arm'].arm_project_package.replace('.', '/') + '/node/'
    group_name = arm.utils.safe_source_name(node_group.name)

    with open(path + group_name + '.hx', 'w') as f:
        f.write('package ' + bpy.data.worlds['Arm'].arm_project_package + '.node;\n\n')
        f.write('import armory.logicnode.*;\n\n')
        f.write('@:keep class ' + group_name + ' extends armory.Trait {\n\n')
        f.write('\tpublic function new() { super(); notifyOnAdd(add); }\n\n')
        f.write('\tfunction add() {\n')
        for node in root_nodes:
            name = '_' + node.name.replace('.', '_').replace(' ', '')
            build_node(node_group, node, f)
        f.write('\t}\n')
        f.write('}\n')

def build_node(node_group, node, f):
    global parsed_nodes

    # Get node name
    name = '_' + node.name.replace('.', '_').replace(' ', '')

    # Check if node already exists
    if name in parsed_nodes:
        return name

    # Create node
    node_type = node.bl_idname[:-4] # Scrap TimeNode'Type'
    f.write('\t\tvar ' + name + ' = new ' + node_type + '(this);\n')
    parsed_nodes.append(name)
    
    # Properties
    for i in range(0, 5):
        if hasattr(node, 'property' + str(i)):
            f.write('\t\t' + name + '.property' + str(i) + ' = "' + getattr(node, 'property' + str(i)) + '";\n')
    
    # Create inputs
    for inp in node.inputs:
        # Is linked - find node
        inp_name = 'new NullNode(this)'
        if inp.is_linked:
            n = inp.links[0].from_node
            inp_name = build_node(node_group, n, f)
        # Not linked - create node with default values
        else:
            inp_name = build_default_node(inp)
        # Add input
        f.write('\t\t' + name + '.addInput(' + inp_name + ');\n')
        
    return name
    
def get_root_nodes(node_group):
    roots = []
    for node in node_group.nodes:
        if node.type == 'FRAME':
            continue
        linked = False
        for out in node.outputs:
            if out.is_linked:
                linked = True
                break
        if not linked: # Assume node with no connected outputs as roots
            roots.append(node)
    return roots

def build_default_node(inp):
    inp_name = 'new NullNode(this)'
    if inp.type == 'VECTOR':
        inp_name = 'new VectorNode(this, ' + str(inp.default_value[0]) + ', ' + str(inp.default_value[1]) + ', ' + str(inp.default_value[2]) + ')'
    elif inp.type == 'VALUE':
        inp_name = 'new FloatNode(this, ' + str(inp.default_value) + ')'
    elif inp.type == 'BOOLEAN':
        inp_name = 'new BoolNode(this, ' + str(inp.default_value).lower() + ')'
    return inp_name