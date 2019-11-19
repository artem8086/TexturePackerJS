path = require  'path'
fs = require 'fs'
texturePacker = require 'free-tex-packer-core'

options =
	allowRotation: false
	detectIdentical: true
	allowTrim: true
	packer: 'MaxRectsPacker'
	packerMethod: 'Smart'
	removeFileExtension: true
	prependFolderName: false

exportDir = fs.readFileSync(path.join(__dirname, 'export_dir.txt')).toString()
console.log 'Export directory: ' + exportDir + ' ...'

createFrame = (data, cenX, cenY, offsX, offsY) ->
	frame =
		x: data.frame.x
		y: data.frame.y
		w: data.frame.w
		h: data.frame.h
		cx: data.spriteSourceSize.x - Math.floor(data.sourceSize.w * cenX) + offsX
		cy: data.spriteSourceSize.y - Math.floor(data.sourceSize.h * cenY) + offsY


saveImage = (items, info) ->
	exDir = path.join exportDir, info.dir
	unless fs.existsSync exDir
		fs.mkdirSync exDir

	packInfo = JSON.parse items['pack-result.json'].buffer.toString()

	packObj = {}

	cenX = info.cenX || 0.5
	cenY = info.cenY || 0.5
	offsX = info.offsX || 0
	offsY = info.offsY || 0

	ignore = info.ignore || []

	createSet = (set, cenX, cenY, offsX, offsY) ->
		if set.constructor == Object
			createSet set.name, set.cenX || cenX, set.cenY || cenY, set.offsX || offsX, set.offsY || offsY
		else
			name = set
			if name.endsWith '*'
				name = name.slice 0, -1
				frames = []
				index = 0
				while packInfo.frames[name + i]
					ignore[name + i] = true
					frames.push createFrame packInfo.frames[name + i], cenX, cenY, offsX, offsY
				frames
			else
				ignore[name] = true
				createFrame packInfo.frames[name], cenX, cenY, offsX, offsY

	if info.set
		for name, set of info.set
			if set.constructor == Array
				frames = []
				for obj in set
					f = createSet obj, cenX, cenY, offsX, offsY
					if f.constructor == Array
						for frame in f
							frames.push frame
					else
						frames.push f
				packObj[name] = frames
			else
				packObj[name] = createSet set, cenX, cenY, offsX, offsY

	for name, frame of packInfo.frames
		unless ignore[name]
			packObj[name] = createFrame frame, cenX, cenY, offsX, offsY

	fs.writeFile path.join(exDir, info.name + '.json'), JSON.stringify(packObj), ->
	fs.writeFile path.join(exDir, info.name + '.png'), items['pack-result.png'].buffer, ->
	null

pack2Texture = (dir, files) ->
	console.log '- export: ' + dir
	images = []
	for file in files
		images.push
			path: file
			contents: fs.readFileSync path.join dir, file

	texturePacker images, options, (files) ->
		items = []
		for item in files
			items[item.name] = item
		
		info = JSON.parse fs.readFileSync path.join dir, 'animset.json'

		saveImage items, info

convertDir = (dir) ->
	fs.readdir dir, (err, items) ->
		if err then return

		files = []
		for file in items
			if fs.statSync(path.join(dir, file)).isDirectory()
				convertDir path.join dir, file
			else
				if file.endsWith '.png'
					files.push file

		if files.length != 0
			pack2Texture dir, files

convertDir path.join __dirname, 'assets'