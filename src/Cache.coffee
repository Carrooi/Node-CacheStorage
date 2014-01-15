isFunction = (obj) -> return Object.prototype.toString.call(obj) == '[object Function]'

class Cache


	@FILES = 'files'

	@TAGS = 'tags'

	@EXPIRE = 'expire'

	@ITEMS = 'items'

	@PRIORITY = 'priority'

	@ALL = 'all'

	@TIME_FORMAT = 'YYYY-MM-DD HH:mm'

	@fs: null

	storage: null

	async: null

	namespace: null


	constructor: (@storage, @namespace) ->
		if @storage !instanceof require('./Storage/Storage')
			throw new Error 'Cache: storage must be instance of cache-storage/Storage/Storage'

		@async = @storage.async
		@storage.cache = @


	@mockFs: (tree = {}, info = {}) ->
		FS = require 'fs-mock'
		Cache.fs = new FS(tree, info)
		return Cache.fs


	@restoreFs: ->
		if typeof window != 'undefined'
			throw new Error 'Testing with fs module is not allowed in browser.'

		Cache.fs = require 'fs'


	@getFs: ->
		if Cache.fs == null
			Cache.restoreFs()

		return Cache.fs


	generateKey: (key) ->
		hash = 0
		if key.length == 0 then return hash
		max = key.length - 1
		for i in [0..max]
			ch = key.charCodeAt(i)
			hash = ((hash << 5) - hash) + ch
			hash |= 0

		return hash


	load: (key, fallback = null, fn = null) ->
		if @async && arguments.length == 2
			fn = fallback
			fallback = null

		if @async
			@storage.read(@generateKey(key), (err, data) =>
				if err
					fn(err, null)
				else if data == null && fallback != null
					@save(key, fallback, (err, data) ->
						fn(err, data)
					)
				else
					fn(null, data)
			)
		else
			data = @storage.read(@generateKey(key))
			if data == null && fallback != null
				return @save(key, fallback)
			return data


	save: (key, data, dependencies = {}, fn = null) ->
		if isFunction(dependencies)
			fn = dependencies
			dependencies = {}

		key = @generateKey(key)

		if isFunction(data)
			data = data()

		if @async
			if data == null
				@storage.remove(key, (err) ->
					if err
						fn(err, null)
					else
						fn(null, data)
				)
			else
				@storage.parseDependencies(dependencies, (err, dependencies) =>
					if err
						fn(err, null)
					else
						@storage.write(key, data, dependencies, (err) ->
							if err
								fn(err, null)
							else
								fn(null, data)
						)
				)
		else
			if data == null
				@storage.remove(key)
			else
				@storage.write(key, data, @storage.parseDependencies(dependencies))

		return data


	remove: (key, fn = null) ->
		return @save(key, null, fn)


	clean: (conditions, fn = null) ->
		@storage.clean(conditions, fn)
		return @


module.exports = Cache