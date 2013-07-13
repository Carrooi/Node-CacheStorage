crypto = require 'crypto'
path = require 'path'
moment = require 'moment'
fs = require 'fs'

class Cache


	@FILES = 'files'

	@TAGS = 'tags'

	@EXPIRE = 'expire'

	@ALL = 'all'

	@TIME_FORMAT = 'YYYY-MM-DD HH:mm'


	storage: null

	namespace: null


	constructor: (@storage, @namespace) ->
		@storage.cache = @


	generateKey: (key) ->
		return crypto.createHash('sha1').update(key).digest('hex')


	parseDependencies: (dependencies) ->
		typefn = Object.prototype.toString

		if typefn.call(dependencies) == '[object Object]'
			if typeof dependencies[Cache.FILES] != 'undefined'
				files = {}
				for file in dependencies[Cache.FILES]
					file = path.resolve(file)
					files[file] = (new Date(fs.statSync(file).mtime)).getTime()
				dependencies[Cache.FILES] = files
			if typeof dependencies[Cache.EXPIRE] != 'undefined'
				switch typefn.call(dependencies[Cache.EXPIRE])
					when '[object String]' then time = moment(dependencies[Cache.EXPIRE], Cache.TIME_FORMAT)
					when '[object Object]' then time = moment().add(dependencies[Cache.EXPIRE])
					else throw new Error 'Expire format is not valid'
				dependencies[Cache.EXPIRE] = time.valueOf()

		return dependencies


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
			@storage.write(key, data, @parseDependencies(dependencies))

		return data


	remove: (key) ->
		return @save(key, null)


	clean: (conditions) ->
		@storage.clean(conditions)
		return @


module.exports = Cache