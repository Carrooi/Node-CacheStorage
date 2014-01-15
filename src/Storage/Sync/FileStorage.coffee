Storage = require './Storage'
Cache = require '../../Cache'

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
		if !Cache.getFs().existsSync(@directory)
			throw new Error 'FileStorage: directory ' + @directory + ' does not exists'
		if !Cache.getFs().statSync(@directory).isDirectory()
			throw new Error 'FileStorage: path ' + @directory + ' must be directory'


	getFileName: ->
		return @directory + '/__' + @cache.namespace + '.json'


	loadData: ->
		if @allData == null
			file = @getFileName()
			if Cache.getFs().existsSync(file)
				@allData = JSON.parse(Cache.getFs().readFileSync(file, encoding: 'utf8'))
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
		@allData =
			data: @data
			meta: @meta

		file = @getFileName()
		Cache.getFs().writeFileSync(file, JSON.stringify(
			data: @data
			meta: @meta
		))


module.exports = FileStorage
