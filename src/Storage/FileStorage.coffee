Storage = require './Storage'
Cache = require '../Cache'

fs = null
path = null

class FileStorage extends Storage


	directory: null

	allData: null

	data: null

	meta: null


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


	loadData: ->
		if @allData == null
			file = @getFileName()
			if fs.existsSync(file)
				@allData = JSON.parse(fs.readFileSync(file, encoding: 'utf8'))
			else
				@allData = {data: {}, meta: {}}

		return @allData


	getData: ->
		if @data == null
			@data = @loadData().data

		return @data


	getMeta: ->
		if @meta == null
			@meta = @loadData().meta

		return @meta


	writeData: (@data, @meta) ->
		file = @getFileName()
		fs.writeFileSync(file, JSON.stringify(
			data: @data
			meta: @meta
		))
		return @


module.exports = FileStorage
