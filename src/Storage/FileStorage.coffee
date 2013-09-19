Storage = require './Storage'
Cache = require '../Cache'

fs = null
path = null

class FileStorage extends Storage


	directory: null


	constructor: (@directory) ->
		if typeof window != 'undefined'
			throw new Error 'FileStorage: Can not use this storage in browser'

		fs = require 'fs'
		path = require 'path'

		@directory = path.resolve(@directory)
		if !fs.existsSync(@directory)
			throw new Error 'FileStorage: directory ' + @directory + ' does not exists'
		if !fs.statSync(@directory).isDirectory()
			throw new Error 'FileStorage: path ' + @directory + ' must be directory'


	getFileName: ->
		return @directory + '/__' + @cache.namespace + '.json'


	getData: ->
		if @data == null
			file = @getFileName()
			if fs.existsSync(file)
				data = JSON.parse(fs.readFileSync(file, encoding: 'utf8'))
				@data = data.data
				@meta = data.meta
			else
				@data = {}
				@meta = {}
		return @data


	writeData: (@data, @meta) ->
		file = @getFileName()
		fs.writeFileSync(file, JSON.stringify(
			data: @data
			meta: @meta
		))
		return @


module.exports = FileStorage
