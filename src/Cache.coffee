class Cache


	@FILES = 'files'

	@TAGS = 'tags'

	@EXPIRE = 'expire'

	@ITEMS = 'items'

	@PRIORITY = 'priority'

	@ALL = 'all'

	@TIME_FORMAT = 'YYYY-MM-DD HH:mm'

	storage: null

	namespace: null


	constructor: (@storage, @namespace) ->
		@storage.cache = @


	generateKey: (key) ->
		hash = 0
		if key.length == 0 then return hash
		max = key.length - 1
		for i in [0..max]
			char = key.charCodeAt(i)
			hash = ((hash << 5) - hash) + char
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