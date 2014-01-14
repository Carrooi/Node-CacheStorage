isWindow = if typeof window == 'undefined' then false else true

if !isWindow
	path = require 'path'

BaseStorage = require '../Storage'
moment = require 'moment'
Cache = require '../../Cache'

async = require 'async'

class Storage extends BaseStorage


	async: true


	read: (key, fn) ->
		@getData( (data) =>
			if typeof data[key] == 'undefined'
				fn(null)
			else
				@findMeta(key, (meta) =>
					@verify(meta[key], (state) =>
						if state
							fn(data[key])
						else
							@remove(key, ->
								fn()
							)
					)
				)
		)


	write: (key, data, dependencies = {}, fn) ->
		@getData( (all) =>
			all[key] = data
			@getMeta( (meta) =>
				meta[key] = dependencies
				@writeData(all, meta, ->
					fn()
				)
			)
		)


	remove: (key, fn) ->
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


	clean: (conditions, fn) ->
		typeFn = Object.prototype.toString
		type = typeFn.call(conditions)
		if conditions == Cache.ALL
			@writeData({}, {}, fn)

		else if type == '[object Object]'
			keys = []
			if typeof conditions[Cache.TAGS] != 'undefined'
				if typeFn(conditions[Cache.TAGS]) == '[object String]' then conditions[Cache.TAGS] = [conditions[Cache.TAGS]]
				for tag in conditions[Cache.TAGS]
					for key in @findKeysByTag(tag)
						keys.push(key)
						@remove(key)

			if typeof conditions[Cache.PRIORITY] != 'undefined'
				for key in @findKeysByPriority(conditions[Cache.PRIORITY])
					keys.push(key)
					@remove(key)

			async.each(keys, (key, cb) =>
				@remove(key, ->
					cb()
				)
			, ->
				fn()
			)

		return @


	findMeta: (key, fn) ->
		@getMeta( (meta) ->
			if typeof meta[key] != 'undefined'
				fn(meta[key])
			else
				fn(null)
		)


	findKeysByTag: (tag, fn) ->
		@getMeta( (metas) ->
			result = []
			for key, meta of metas
				if typeof meta[Cache.TAGS] != 'undefined' && meta[Cache.TAGS].indexOf(tag) != -1
					result.push(key)
			fn(result)
		)


	findKeysByPriority: (priority, fn) ->
		@getMeta( (metas) ->
			result = []
			for key, meta of metas
				if typeof meta[Cache.PRIORITY] != 'undefined' && meta[Cache.PRIORITY] <= priority
					result.push(key)
			fn(result)
		)


	verify: (meta, fn) ->
		typefn = Object.prototype.toString

		if typefn.call(meta) == '[object Object]'
			if typeof meta[Cache.EXPIRE] != 'undefined'
				if moment().valueOf() >= meta[Cache.EXPIRE]
					fn(false)
					return null

			if typeof meta[Cache.ITEMS] == 'undefined'
				meta[Cache.ITEMS] = []

			async.each(meta[Cache.ITEMS], (item, cb) =>
				@findMeta(item, (item) ->
					if item == null
						fn(false)
						cb(new Error 'Fake error')
					else if item != null
						@verify(item, (state) ->
							if state == false
								fn(false)
								cb(new Error 'Fake error')
							else
								cb()
						)
					else
						cb()
				)
			, (err) =>
				if !err
					if typeof meta[Cache.FILES] == 'undefined'
						meta[Cache.FILES] = []

					@checkFilesSupport()
					if isWindow
						for file, time of meta[Cache.FILES]
							mtime = window.require.getStats(file).mtime
							if mtime == null
								throw new Error 'File stats are disabled in your simq configuration. Can not get stats for ' + file + '.'

							if window.require.getStats(file).mtime.getTime() != time
								fn(false)
					else
						for file, time of meta[Cache.FILES]
							files = []
							files.push(file: file, time: time) for file, time of meta[Cache.FILES]
							async.each(files, (item, cb) =>
								Cache.getFs().stat(file, (err, stats) ->
									if err
										cb(err)
									else
										if (new Date(stats.mtime)).getTime() != time
											fn(false)
											cb(new Error 'Fake error')
								)
							, (err) ->
								if err && err.message == 'Fake error'
									# skip
								else if err
									throw err
								else
									fn(true)
							)
			)

		fn(true)


	parseDependencies: (dependencies, fn) ->
		typefn = Object.prototype.toString
		result = {}

		if typefn.call(dependencies) == '[object Object]'
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

			if typeof dependencies[Cache.FILES] != 'undefined'
				@checkFilesSupport()
				files = {}
				if isWindow
					for file in dependencies[Cache.FILES]
						mtime = window.require.getStats(file).mtime
						if mtime == null
							throw new Error 'File stats are disabled in your simq configuration. Can not get stats for ' + file + '.'
						file = window.require.resolve(file)
						files[file] = mtime.getTime()
				else
					async.each(dependencies[Cache.FILES], (file, cb) ->
						file = path.resolve(file)
						Cache.getFs().stat(file, (err, stats) ->
							if err
								cb(err)
							else
								files[file] = (new Date(stats.mtime)).getTime()
								cb()
						)
					, (err) ->
						if err
							throw err
						else
							result[Cache.FILES] = files
							fn(result)
					)
					for file in dependencies[Cache.FILES]
						file = path.resolve(file)
						files[file] = (new Date(Cache.getFs().statSync(file).mtime)).getTime()

				result[Cache.FILES] = files

			else
				fn(result)

		else
			fn(result)


module.exports = Storage