macroScript Batch_Camera_Lister category:"gugu" tooltip:"Batch Camera Lister"
Icon:#("Render", 7)
(
global sceneListArr = #()

try(destroyDialog sceneListRo )catch()

fn prepareScene = (
	-- Scene States
	global SceneStates = #()
		
	-- Getting Cams
	global CamCollection = for cams in cameras where superClassOf cams ==camera collect cams
	if CamCollection == undefined then CamCollection = #()
	
	-- sort function
	fn compareNames str1 str2 = stricmp str1.name str2.name
	-- run sort function
	if CamCollection != undefined then qSort CamCollection compareNames
	
	-- Scene States
	global ssm = sceneStateMgr
	for i in 1 to ssm.getCount() do 
	(
		SceneStates[i] = ssm.GetSceneState i
	)
)

	-- set current view
fn SetCurrentView index = (
	index = index as integer
	viewport.setCamera CamCollection[index]
	
	if SceneStates.count > 1 then (
		sceneName = ssm.GetSceneState ((getUserProp (CamCollection[index]) "SceneState") as integer)
		if sceneName != undefined then ssm.RestoreAllParts (sceneName)
	)

	renderWidth= (getUserProp (CamCollection[index]) "RenderWidth") as integer
	renderHeight= (getUserProp (CamCollection[index]) "RenderHeight") as integer
	displaySafeFrames = true
)

	-- render cameras
fn RenderScene = (
	-- path error
	
		for rendering in 1 to CamCollection.count do (
			-- close scene dialog
			renderSceneDialog.close()
			index = rendering as integer
			-- set current view
			cam = CamCollection[index]
			SetCurrentView index
			
			-- get render props
			renderPath = (GetAppData trackViewNodes 001) as string
			renderWidth= (getUserProp cam "RenderWidth") as integer * (GetAppData trackViewNodes 004 as float)
			renderHeight= (getUserProp cam "RenderHeight") as integer * (GetAppData trackViewNodes 004 as float)
			
			-- render
			if((getUserProp cam "RenderCheck") == true) then (
				max quick render
				CoronaRenderer.CoronaFp.saveAllElements ((renderPath+"\\"+(cam.name as string)+(GetAppData trackViewNodes 005 as string)) as string)
				if ((getAppData TrackViewNodes 006) as booleanClass) then CoronaRenderer.CoronaFp.dumpVfb ((renderPath+"\\"+(cam.name as string)+".cxr") as string)
				--deleteFile ((renderPath+"\\"+(cam.name as string)+".Alpha"+saveFormat) as string)
			)
		)
)	

rollout sceneListRo "Batch Render" width:700 height:200 (
	edittext batchFile "" pos:[0,10,0] width:700
	button startRender "START" pos:[5,40,0] width:100 height:30
	checkbox resX "ResX Override?" pos:[230,40,0]
	spinner resXSpinner range:[0.05,10,1] pos:[230,60,0] width:50
	checkbox noiseCheck "Noise Override" pos:[340,40,0]
	spinner noiseSpinner range:[1,10,5] pos:[340,60,0] width:50
	checkbox drCheck "DR Enabled?" pos:[440,40,0]
	checkbox denoiseCheck "Denoise?" pos:[530,40,0]
	edittext sceneLabel "Scene List" pos:[5,80,0] align:#left readOnly:true border:false width:695 height:30 labelOnTop:true
	
	on startRender pressed do (
		if resX.checked then setAppData TrackViewNodes 004 (resXSpinner.value as string)
		local file = openFile (batchFile.text as string) mode:"r"
		local line_cnt = 0
		Global Paths=#() --the array that will hold the paths
	
		while not eof file do 
		(
			r=  readLine file --read the first line and store as a string it in r
			append paths r --append the first line to paths array
			line_cnt += 1 --add 1 to the counter
		)
		
		
		for i in Paths do (
			sceneLabel.text+=i+"\n"
			sceneLabel.height+=10
		)
		
		for i in Paths do (
			maxfile = loadMaxFile (i as string) quiet:true
			if resX.checked then setAppData TrackViewNodes 004 (resXSpinner.value as string)
			if noiseCheck.checked then renderers.current.adaptivity_targetError=noiseSpinner.value
			if drCheck.checked then (
				renderers.current.dr_enable=true
				renderers.current.dr_searchDuringRender=true
			)
			if denoiseCheck.checked then (
				renderers.current.denoise_filterType=2
			)
			prepareScene()
			RenderScene()
			resetMaxFile #noPrompt
		)
	)
)
createDialog sceneListRo style:#(#style_titlebar, #style_border, #style_sysmenu, #style_resizing)	
)