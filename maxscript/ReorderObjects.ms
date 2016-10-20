-------------------------------------------------------
-- HOW TO USE
-- drag this script into Max
--   this script will create a trackview named 'reorder',
--   please minimize it when using the script.
-------------------------------------------------------

rollout reorder_objs "Object Reordering" width: 250
(
	
	-----------------------------------------------------------------------------------------
	global g_trackview
	global g_tvObjects
	global g_parent
	
	-----------------------------------------------------------------------------------------
	group "About"
	(
		label rtv1 "Object Reordering"
		label rtv2 "Version 1.0 (2016.10.20)"
		label rtv3 "by Shaochun"
	)
	
	-----------------------------------------------------------------------------------------
	group "Object Order"
	(
    --	listBox objectOrderListBox "" height: 30 items:(for o in selection collect o.name)
    	listBox objectOrderListBox "" height: 30
	)

	-----------------------------------------------------------------------------------------
	group "Reorder Selection"
	(
		button moveup	"MOVE UP"	width:80 	height:20 across:2	align:#center 	enabled:true 
		button movedown	"MOVE DN"	width:80 	height:20 			align:#center 	enabled:true
		button addd		"ADD"		width:50 	height:20 across:3	align:#center 	enabled:true
		button removee	"REMOVE"	width:50 	height:20 			align:#center 	enabled:true
		button clearr	"CLEAR"		width:50 	height:20 			align:#center 	enabled:true
		button findd	"FIND"		width:200 	height:20 across:1	align:#center 	enabled:true
	)

	-----------------------------------------------------------------------------------------
	-- make sure we have a trackview in scene
	-----------------------------------------------------------------------------------------
	fn initiate =
	(
		--tv exists
		if (trackviews.exists "reorder") then
		(
			g_trackview = trackviews.getTrackView "reorder"
			trackviews.setCurrent "reorder" 
			print "reorder_objs: trackview [reorder] found."
		)

		--tv not exist
		else
		(
			trackviews.open "reorder" -- create a Track View
			g_trackview = trackviews.getTrackView "reorder"
			trackviews.setCurrent "reorder" 
			print "reorder_objs: trackview not exist and a new one has been created."
		)

		print "reorder_objs: sucessfully loaded."
	)

	-----------------------------------------------------------------------------------------
	fn refreshObjectNameInListbox =
	(
		--print "refreshObjectNameInListbox() triggered."
		print g_tvObjects
		objectOrderListBox.items = for obj in g_tvObjects collect obj.name
	)

	-----------------------------------------------------------------------------------------
	fn updateNameProc =
	(
		--- WE ONLY HAVE TO CHANGE THE LISTBOX ITEM NAME. OBJECT NAME IN g_tvObjects WILL GET UPDATED AUTOLY MY MAX	
		local np = callbacks.notificationParam() --returns #nodeNameSet: #(old_name, new_name, node)	
		local oldnameindex = findItem objectOrderListBox.items np[1]
		--	print oldnameindex
		--	print np[2]
		if oldnameindex > 0 then 
		(
			local a = objectOrderListBox.items
			a[oldnameindex] = np[2]
			objectOrderListBox.items = a
		)
		else print "reorder_objs: oldnameindex is 0."
	)

	-----------------------------------------------------------------------------------------
	fn selectProc =
	(
		--print("reorder_objs: selectProc triggered.")
		if (selection.count == 1) do
		(
			local obj = selection[1]
			local index = findItem objectOrderListBox.items obj.name
			if index > 0 do objectOrderListBox.selection = index
		)
	)

	-----------------------------------------------------------------------------------------
	-- trackview.getNumTracks() will only handle the selected objects
	-- make sure you select something when using the function
	-----------------------------------------------------------------------------------------
	fn refreshObjects =
	(
		local objectStringList = #()
		local objectList = #() --this is used in moveup/down

		for i=1 to g_trackview.getNumTracks() do
		(
  			if superClassOf(g_trackview.gettrack i) == GeometryClass do
  			(

  				objectWithNameAndTransform = g_trackview.gettrack i

				-- this is a hack to avoid this: http://imgur.com/a/VJfEL
				-- 非DopeSheet trackview 會多抓一個; we have to ignore it
				local objectWithNameString = ""
				try
				(
					objectWithNameString = objectWithNameAndTransform.name

					--this is only proceed if the above doesn't fail
					append objectStringList (objectWithNameString)
					append objectList (objectWithNameAndTransform)
				)
				catch
				(
				)
				
    		)
		)
		objectOrderListBox.items = objectStringList
	
	--	return objectList --used in moveup/down
		g_tvObjects = objectList
	)

	-----------------------------------------------------------------------------------------
	on reorder_objs open do
	(
		initiate()
		refreshObjects()

		callbacks.addScript #selectionSetChanged "reorder_objs.selectProc()" 	id:#MainDialogCallbacks
		callbacks.addScript #filePostOpen	     "reorder_objs.initiate()"       id:#MainDialogCallbacks
		callbacks.addScript #nodeNameSet		 "reorder_objs.updateNameProc()" id:#MainDialogCallbacks
	)


	-----------------------------------------------------------------------------------------
	on reorder_objs close do
	(
	----這個COMMENT OUT -- 不然如果開兩個以上的rollout 新舊, 如果把舊的關掉, 新的失效了
	--	callbacks.removeScripts #selectionSetChanged id:#MainDialogCallbacks
	--	callbacks.removeScripts #filePostOpen		 id:#MainDialogCallbacks
	--	callbacks.removeScripts #nodeNameSet		 id:#MainDialogCallbacks		
	)

	-----------------------------------------------------------------------------------------
	on addd pressed do
	(
		refreshObjects()
	)
	
	on removee pressed do
	(
		if (objectOrderListBox.selection == 0) do return false

		deleteItem g_tvObjects 				objectOrderListBox.selection

		--deleteItem objectOrderListBox.items objectOrderListBox.selection
		local a = objectOrderListBox.items
		deleteItem a objectOrderListBox.selection
		objectOrderListBox.items = a

	)
	
	on clearr pressed do
	(
		g_tvObjects = #()
		objectOrderListBox.items = #()
	)

	on findd pressed do
	(
		if selection.count == 1 do
		(
			--print selection[1].name			
			local found_index = findItem g_tvObjects selection[1]
			objectOrderListBox.selection = found_index
		)
	)

	-----------------------------------------------------------------------------------------
	on objectOrderListBox selected nameIndex do
	(
	--	print objectOrderListBox.items[nameIndex]
	--	print (getNodeByName objectOrderListBox.items[nameIndex])
		try
		(
			select (getNodeByName objectOrderListBox.items[nameIndex])
		)
		catch
		(
			print "reorder_objs: select error."

			-- THIS IS FIXED. IT'S CAUSED BY THE RENAMED-OBJECT NOT REFLECT INTO THE LISTBOX ITEM NAME.

			-- MAXScript Rollout Handler Exception:
			-- No ""select"" function for undefined
		)
	)

	-----------------------------------------------------------------------------------------
	-- make sure the selection has the same parent
	-----------------------------------------------------------------------------------------
	fn checkSameParent =
	(
		local invalidObjects = #()
		local invalidParents = #()
		local prev_parent

		if (g_tvObjects.count > 0) then prev_parent = g_tvObjects[1].parent
		else return false

		for obj in g_tvObjects do
		(
			if obj.parent == prev_parent then continue
			else
			(
				append invalidObjects obj 
				appendIfUnique invalidParents obj.parent
				prev_parent = obj.parent
			)
		)

		if (invalidObjects.count > 0) then
		(
			messageBox("added objects should have the same parent.");
			return false;
		)
		else 
		(
			g_parent = g_tvObjects[1].parent
			print ("g_parent= " + g_parent as string)
			return true;
		)
	)

	-----------------------------------------------------------------------------------------
	on movedown pressed do
	(
		if not checkSameParent() do return false

		local ol 	     	 = g_tvObjects
		local selected_index = objectOrderListBox.selection

		if selected_index == objectOrderListBox.items.count do return false --ignore if item at list last

		--- move object down -----------
		d = dummy()
--this need work		if (g_parent != undefined) do d.parent = g_parent

		for i=ol.count to selected_index+2 by -1 do ol[i].parent = d
		ol[selected_index].parent   = d
		ol[selected_index+1].parent = d
		for i=selected_index-1 to 1 by -1 do ol[i].parent = d

		delete d
--this need work		if (g_parent != undefined) do for olo in ol do olo.parent = g_parent

		select g_tvObjects
		refreshObjects()
		
		objectOrderListBox.selection = objectOrderListBox.selection + 1
		select g_tvObjects[objectOrderListBox.selection]
	)

	-----------------------------------------------------------------------------------------
	on moveup pressed do
	(
		if not checkSameParent() do return false

		local ol 	     	 = g_tvObjects
		local selected_index = objectOrderListBox.selection

		if selected_index == 1 do return false --ignore if item at list first

		--- move object up -------------
		d = dummy()
--this need work		if (g_parent != undefined) do d.parent = g_parent
		
		for i=ol.count to selected_index+1 by -1 do ol[i].parent = d
		ol[selected_index-1].parent = d
		ol[selected_index].parent   = d
		for i=selected_index-2 to 1 by -1 do ol[i].parent = d

		delete d
--this need work		if (g_parent != undefined) do for olo in ol do olo.parent = g_parent

		select g_tvObjects
		refreshObjects()
		
		objectOrderListBox.selection = objectOrderListBox.selection - 1
		select g_tvObjects[objectOrderListBox.selection]
	)

)--end rollout

-----------------------------------------------------------------------------------------
createDialog reorder_objs
