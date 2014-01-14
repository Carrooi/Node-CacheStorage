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


	loadData: (fn) ->
		if @allData == null
			file = @getFileName()
			Cache.getFs().exists(file, (exists) =>
				if exists
					Cache.getFs().readFile(file, encoding: 'utf8', (err, data) =>
						if err
							throw err

						@allData = JSON.parse(data)
						fn(@allData)
					)
				else
					@allData = {data: {}, meta: {}}
					fn(@allData)
			)

		else
			fn(@allData)


	getData: (fn) ->
		@loadData( (data) ->
			fn(data.data)
		)


	getMeta: (fn) ->
		@loadData( (data) ->
			fn(data.meta)
		)


	writeData: (@data, @meta, fn) ->
		@allData =
			data: @data
			meta: @meta

		file = @getFileName()
		Cache.getFs().writeFile(file, JSON.stringify(
			data: @data
			meta: @meta
		), (err) ->
			if err
				throw err

			fn()
		)
		return @


module.exports = FileStorage
