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

	namespace: null


	constructor: (@storage, @namespace) ->
		if @storage !instanceof require('./Storage/Storage')
			throw new Error 'Cache: storage must be instance of cache-storage/Storage/Storage'

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


	load: (key, fallback = null) ->
		data = @storage.read(@generateKey(key))
		if data == null && fallback != null
			return @save(key, fallback)
		return data


	save: (key, data, dependencies = {}) ->
		key = @generateKey(key)

		if Object.prototype.toString.call(data) == '[object Function]'
			data = data()

		if data == null
			@storage.remove(key)
		else
			@storage.write(key, data, @storage.parseDependencies(dependencies))

		return data


	remove: (key) ->
		return @save(key, null)


	clean: (conditions) ->
		@storage.clean(conditions)
		return @


module.exports = Cache