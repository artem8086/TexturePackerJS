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

pack2Texture = (dir, files) ->
	images = []
	for file in files
		images.push
			path: file
			contents: fs.readFileSync path.join dir, file

	texturePacker images, options, (files) ->
		for item in files
			fs.writeFile path.join(dir, item.name), item.buffer, ->

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