----------------------------------------------------------------------------
-- A simple Maxscript helps dumping vertex's id and local positions.
----------------------------------------------------------------------------

-- 1. select the object first
-- 2. In Max open the MaxScript Listener (F11), goto File > Run Script... (CTRL+R), and choose this file.
-- 3. the vertex id and position should be dumped to the Listener.
-- 4. Enjoy.

p = convertToPoly($)
num_verts = p.GetNumVertices()
in coordsys local vert_coords = for vid = 1 to num_verts collect #(vid , polyOp.getVert p vid)
print vert_coords
