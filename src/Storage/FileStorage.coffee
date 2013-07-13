fs = require 'fs'
Storage = require './Storage'
Cache = require '../Cache'

class FileStorage extends Storage


	directory: null

	data: null

	meta: null


	constructor: (@directory) ->


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
		if type == '[object Array]' && conditions.indexOf(Cache.ALL) != -1
			@writeData({}, {})
		else if type == '[object Object]' && typeof conditions[Cache.TAGS] != 'undefined'
			if typeFn(conditions[Cache.TAGS]) == '[object String]' then conditions[Cache.TAGS] = [conditions[Cache.TAGS]]
			for tag in conditions[Cache.TAGS]
				for key in @findKeysByTag(tag)
					@remove(key)

		return @


module.exports = FileStorage
