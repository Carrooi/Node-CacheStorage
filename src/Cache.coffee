crypto = require 'crypto-browserify'

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
		return crypto.createHash('sha1').update(key).digest('hex')


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