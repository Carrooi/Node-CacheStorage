isWindow = if typeof window == 'undefined' then false else true

if !isWindow
	path = require 'path'

moment = require 'moment'
Cache = require '../Cache'

checkFilesSupport = ->
	if isWindow && window.require.simq != true
		throw new Error 'Files meta information can be used in browser only with simq.'

	if isWindow
		version = window.require.version
		if typeof version == 'undefined' || parseInt(version.replace(/\./g, '')) < 510
			throw new Error 'File method information is supported only with simq@5.1.0 and later.'

class Storage


	async: false

	cache: null


	constructor: ->
		if typeof @getData == 'undefined' || typeof @getMeta == 'undefined' || typeof @writeData == 'undefined'
			throw new Error 'Cache storage: you have to implement methods getData, getMeta and writeData.'


	read: (key, fn = null) ->
		if @async
			@getData( (data) =>
				if typeof data[key] == 'undefined'
					fn(null)
				else
					@findMeta(key, (meta) =>
						if @verify(meta[key])
							fn(data[key])
						else
							@remove(key, ->
								fn()
							)
					)
			)
		else
			data = @getData()
			if typeof data[key] == 'undefined'
				return null
			else
				if @verify(@findMeta(key))
					return data[key]
				else
					@remove(key)
					return null


	write: (key, data, dependencies = {}, fn = null) ->
		if @async
			@getData( (all) =>
				all[key] = data
				@getMeta( (meta) =>
					meta[key] = dependencies
					@writeData(all, meta, ->
						fn()
					)
				)
			)
		else
			all = @getData()
			all[key] = data
			meta = @getMeta()
			meta[key] = dependencies
			@writeData(all, meta)
			return @


	remove: (key, fn = null) ->
		if @async
			@getData( (data) =>
				@getMeta( (meta) =>
					if typeof data[key] != 'undefined'
						delete data[key]
						delete meta[key]
					@writeData(data, meta, ->
						fn()
					)
				)
			)
		else
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


	findMeta: (key, fn = null) ->
		if @async
			@getMeta( (meta) ->
				if typeof meta[key] != 'undefined'
					fn(meta[key])
				else
					fn(null)
			)
		else
			meta = @getMeta()
			return if typeof meta[key] != 'undefined' then meta[key] else null


	findKeysByTag: (tag, fn = null) ->
		if @async
			@getMeta( (metas) ->
				result = []
				for key, meta of metas
					if typeof meta[Cache.TAGS] != 'undefined' && meta[Cache.TAGS].indexOf(tag) != -1
						result.push(key)
				fn(result)
			)
		else
			metas = @getMeta()
			result = []
			for key, meta of metas
				if typeof meta[Cache.TAGS] != 'undefined' && meta[Cache.TAGS].indexOf(tag) != -1
					result.push(key)
			return result


	findKeysByPriority: (priority, fn = null) ->
		if @async
			@getMeta( (metas) ->
				result = []
				for key, meta of metas
					if typeof meta[Cache.PRIORITY] != 'undefined' && meta[Cache.PRIORITY] <= priority
						result.push(key)
				fn(result)
			)
		else
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
				checkFilesSupport()
				if isWindow
					for file, time of meta[Cache.FILES]
						mtime = window.require.getStats(file).mtime
						if mtime == null
							throw new Error 'File stats are disabled in your simq configuration. Can not get stats for ' + file + '.'

						if window.require.getStats(file).mtime.getTime() != time then return false
				else
					for file, time of meta[Cache.FILES]
						if (new Date(Cache.getFs().statSync(file).mtime)).getTime() != time then return false

			if typeof meta[Cache.EXPIRE] != 'undefined'
				if moment().valueOf() >= meta[Cache.EXPIRE] then return false

			if typeof meta[Cache.ITEMS] != 'undefined'
				if @async
					throw new Error 'Expiration by items is currently not supported in async storages.'

				for item in meta[Cache.ITEMS]
					item = @findMeta(item)
					if (item == null) || (item != null && @verify(item) == false) then return false

		return true


	parseDependencies: (dependencies) ->
		typefn = Object.prototype.toString
		result = {}

		if typefn.call(dependencies) == '[object Object]'
			if typeof dependencies[Cache.FILES] != 'undefined'
				checkFilesSupport()
				files = {}
				if isWindow
					for file in dependencies[Cache.FILES]
						mtime = window.require.getStats(file).mtime
						if mtime == null
							throw new Error 'File stats are disabled in your simq configuration. Can not get stats for ' + file + '.'
						file = window.require.resolve(file)
						files[file] = mtime.getTime()
				else
					for file in dependencies[Cache.FILES]
						file = path.resolve(file)
						files[file] = (new Date(Cache.getFs().statSync(file).mtime)).getTime()
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
