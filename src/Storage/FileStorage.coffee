fs = require 'fs'
path = require 'path'
Storage = require './Storage'
Cache = require '../Cache'

class FileStorage extends Storage


	directory: null


	constructor: (@directory) ->
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
				data = JSON.parse(fs.readFileSync(file, encoding: 'utf-8'))
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


	getMeta: ->
		if @meta == null then @getData()
		return @meta


	read: (key) ->
		data = @getData()
		if typeof data[key] == 'undefined'
			return null
		else
			if @verify(@findMeta(key))
				return data[key]
			else
				@remove(key)
				return null


	write: (key, data, dependencies = {}) ->
		all = @getData()
		all[key] = data
		meta = @getMeta()
		meta[key] = dependencies
		@writeData(all, meta)
		return @


	remove: (key) ->
		data = @getData()
		meta = @getMeta()
		if typeof data[key] != 'undefined'
			delete data[key]
			delete meta[key]
		@writeData(data, meta)
		return @


	clean: (conditions) ->
		typeFn = Object.prototype.toString
		type = typeFn.call(conditions)
		if conditions == Cache.ALL
			@writeData({}, {})

		else if type == '[object Object]'
			if typeof conditions[Cache.TAGS] != 'undefined'
				if typeFn(conditions[Cache.TAGS]) == '[object String]' then conditions[Cache.TAGS] = [conditions[Cache.TAGS]]
				for tag in conditions[Cache.TAGS]
					for key in @findKeysByTag(tag)
						@remove(key)

			if typeof conditions[Cache.PRIORITY] != 'undefined'
				for key in @findKeysByPriority(conditions[Cache.PRIORITY])
					@remove(key)

		return @


module.exports = FileStorage
