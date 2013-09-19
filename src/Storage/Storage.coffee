isWindow = if typeof window == 'undefined' then false else true

if !isWindow
	fs = require 'fs'
	path = require 'path'

moment = require 'moment'
Cache = require '../Cache'

class Storage


	cache: null


	constructor: ->
		if typeof @getData == 'undefined' || typeof @getMeta == 'undefined' || typeof @writeData == 'undefined'
			throw new Error 'Cache storage: you have to implement methods getData, getMeta and writeData.'


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


	findMeta: (key) ->
		meta = @getMeta()
		return if typeof meta[key] != 'undefined' then meta[key] else null


	findKeysByTag: (tag) ->
		metas = @getMeta()
		result = []
		for key, meta of metas
			if typeof meta[Cache.TAGS] != 'undefined' && meta[Cache.TAGS].indexOf(tag) != -1
				result.push(key)
		return result


	findKeysByPriority: (priority) ->
		metas = @getMeta()
		result = []
		for key, meta of metas
			if typeof meta[Cache.PRIORITY] != 'undefined' && meta[Cache.PRIORITY] <= priority
				result.push(key)
		return result


	verify: (meta) ->
		typefn = Object.prototype.toString

		if typefn.call(meta) == '[object Object]'
			if typeof meta[Cache.FILES] != 'undefined'
				if isWindow then throw new Error 'Files meta information is not supported in browser'

				for file, time of meta[Cache.FILES]
					if (new Date(fs.statSync(file).mtime)).getTime() != time then return false

			if typeof meta[Cache.EXPIRE] != 'undefined'
				if moment().valueOf() >= meta[Cache.EXPIRE] then return false

			if typeof meta[Cache.ITEMS] != 'undefined'
				for item in meta[Cache.ITEMS]
					item = @findMeta(item)
					if (item == null) || (item != null && @verify(item) == false) then return false

		return true


	parseDependencies: (dependencies) ->
		typefn = Object.prototype.toString
		result = {}

		if typefn.call(dependencies) == '[object Object]'
			if typeof dependencies[Cache.FILES] != 'undefined'
				if isWindow then throw new Error 'Files meta information is not supported in browser'

				files = {}
				for file in dependencies[Cache.FILES]
					file = path.resolve(file)
					files[file] = (new Date(fs.statSync(file).mtime)).getTime()
				result[Cache.FILES] = files

			if typeof dependencies[Cache.EXPIRE] != 'undefined'
				switch typefn.call(dependencies[Cache.EXPIRE])
					when '[object String]' then time = moment(dependencies[Cache.EXPIRE], Cache.TIME_FORMAT)
					when '[object Object]' then time = moment().add(dependencies[Cache.EXPIRE])
					else throw new Error 'Expire format is not valid'
				result[Cache.EXPIRE] = time.valueOf()

			if typeof dependencies[Cache.ITEMS] != 'undefined'
				result[Cache.ITEMS] = []
				for item, i in dependencies[Cache.ITEMS]
					result[Cache.ITEMS].push(@cache.generateKey(item))

			if typeof dependencies[Cache.PRIORITY] != 'undefined' then result[Cache.PRIORITY] = dependencies[Cache.PRIORITY]

			if typeof dependencies[Cache.TAGS] != 'undefined' then result[Cache.TAGS] = dependencies[Cache.TAGS]

		return result


module.exports = Storage
