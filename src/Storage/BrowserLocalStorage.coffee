Storage = require './Storage'
Cache = require '../Cache'

class BrowserLocalStorage extends Storage


	@TEST_VALUE = '__--cache-storage--__'


	constructor: ->
		if !BrowserLocalStorage.isSupported()
			throw new Error 'Cache storage: Local storage is not supported'


	@isSupported: ->
		try
			localStorage.setItem(BrowserLocalStorage.TEST_VALUE, BrowserLocalStorage.TEST_VALUE)
			localStorage.getItem(BrowserLocalStorage.TEST_VALUE)
			return true
		catch e
			return false


	getName: ->
		return '__' + @cache.namespace


	getData: ->
		if @data == null
			data = localStorage.getItem(@getName())
			if data == null
				@data = {}
				@meta = {}
			else
				data = JSON.parse(data)
				@data = data.data
				@meta = data.meta
		return @data


	writeData: (@data, @meta) ->
		localStorage.setItem(@getName(), JSON.stringify(
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
		if conditions == Cache.ALL/
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


module.exports = BrowserLocalStorage