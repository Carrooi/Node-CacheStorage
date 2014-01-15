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
		@getData( (err, data) =>
			if err
				fn(err, null)
			else if typeof data[key] == 'undefined'
				fn(null, null)
			else
				@findMeta(key, (err, meta) =>
					if err
						fn(err, null)
					else
						@verify(meta, (err, state) =>
							if err
								fn(err, null)
							else if state
								fn(null, data[key])
							else
								@remove(key, (err) ->
									if err
										fn(err, null)
									else
										fn(null, null)
								)
						)
				)
		)


	write: (key, data, dependencies = {}, fn) ->
		@getData( (err, all) =>
			if err
				fn(err)
			else
				all[key] = data
				@getMeta( (err, meta) =>
					if err
						fn(err)
					else
						meta[key] = dependencies
						@writeData(all, meta, fn)
				)
		)


	remove: (key, fn) ->
		@getData( (err, data) =>
			if err
				fn(err)
			else
				@getMeta( (err, meta) =>
					if err
						fn(err)
					else
						if typeof data[key] != 'undefined'
							delete data[key]
							delete meta[key]

						@writeData(data, meta, fn)
				)
		)


	removeAll: (fn) ->
		@writeData({}, {}, fn)


	clean: (conditions, fn) ->
		typeFn = Object.prototype.toString
		type = typeFn.call(conditions)

		if conditions == Cache.ALL
			@removeAll(fn)

		else if type == '[object Object]'
			if typeof conditions[Cache.TAGS] == 'undefined'
				conditions[Cache.TAGS] = []

			if typeFn(conditions[Cache.TAGS]) == '[object String]'
				conditions[Cache.TAGS] = [conditions[Cache.TAGS]]

			removeKeys = (keys) =>
				async.eachSeries(keys, (key, cb) =>
					@remove(key, (err) ->
						cb(err)
					)
				, (err) ->
					fn(err)
				)

			keys = []
			async.eachSeries(conditions[Cache.TAGS], (tag, cb) =>
				@findKeysByTag(tag, (err, _keys) ->
					keys = keys.concat(_keys)
					cb(err)
				)
			, (err) =>
				if err
					fn(err)
				else if typeof conditions[Cache.PRIORITY] == 'undefined'
					removeKeys(keys)
				else
					@findKeysByPriority(conditions[Cache.PRIORITY], (err, _keys) =>
						if err
							fn(err)
						else
							keys = keys.concat(_keys)
							removeKeys(keys)
					)
			)

		else
			fn(null)

		return @


	findMeta: (key, fn) ->
		@getMeta( (err, meta) ->
			if err
				fn(err, null)
			else if typeof meta[key] != 'undefined'
				fn(null, meta[key])
			else
				fn(null, null)
		)


	findKeysByTag: (tag, fn) ->
		@getMeta( (err, metas) ->
			if err
				fn(err, null)
			else
				result = []
				for key, meta of metas
					if typeof meta[Cache.TAGS] != 'undefined' && meta[Cache.TAGS].indexOf(tag) != -1
						result.push(key)
				fn(null, result)
		)


	findKeysByPriority: (priority, fn) ->
		@getMeta( (err, metas) ->
			if err
				fn(err, null)
			else
				result = []
				for key, meta of metas
					if typeof meta[Cache.PRIORITY] != 'undefined' && meta[Cache.PRIORITY] <= priority
						result.push(key)
				fn(null, result)
		)


	verify: (meta, fn) ->
		typefn = Object.prototype.toString

		if typefn.call(meta) == '[object Object]'
			if typeof meta[Cache.EXPIRE] != 'undefined'
				if moment().valueOf() >= meta[Cache.EXPIRE]
					fn(null, false)
					return null

			if typeof meta[Cache.ITEMS] == 'undefined'
				meta[Cache.ITEMS] = []

			async.eachSeries(meta[Cache.ITEMS], (item, cb) =>
				@findMeta(item, (err, meta) =>
					if err
						fn(err, null)
						cb(new Error 'Fake error')
					else if meta == null
						fn(null, false)
						cb(new Error 'Fake error')
					else if meta != null
						@verify(meta, (err, state) ->
							if err
								fn(err, null)
								cb(new Error 'Fake error')
							else if state == false
								fn(null, false)
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
								fn(null, false)
								return null

						fn(null, true)
					else
						files = []
						for file, time of meta[Cache.FILES]
							files.push(file: file, time: time) for file, time of meta[Cache.FILES]

						async.eachSeries(files, (item, cb) =>
							Cache.getFs().stat(item.file, (err, stats) ->
								if err
									cb(err)
								else
									if (new Date(stats.mtime)).getTime() != item.time
										fn(null, false)
										cb(new Error 'Fake error')
									else
										cb()
							)
						, (err) ->
							if err && err.message == 'Fake error'
								# skip
							else if err
								fn(err, null)
							else
								fn(null, true)
						)
			)

		else
			fn(null, true)


	parseDependencies: (dependencies, fn) ->
		typefn = Object.prototype.toString
		result = {}

		if typefn.call(dependencies) == '[object Object]'
			if typeof dependencies[Cache.EXPIRE] != 'undefined'
				switch typefn.call(dependencies[Cache.EXPIRE])
					when '[object String]'
						time = moment(dependencies[Cache.EXPIRE], Cache.TIME_FORMAT)

					when '[object Object]'
						time = moment().add(dependencies[Cache.EXPIRE])

					else
						throw new Error 'Expire format is not valid'

				result[Cache.EXPIRE] = time.valueOf()

			if typeof dependencies[Cache.ITEMS] != 'undefined'
				result[Cache.ITEMS] = []
				for item in dependencies[Cache.ITEMS]
					result[Cache.ITEMS].push(@cache.generateKey(item))

			if typeof dependencies[Cache.PRIORITY] != 'undefined'
				result[Cache.PRIORITY] = dependencies[Cache.PRIORITY]

			if typeof dependencies[Cache.TAGS] != 'undefined'
				result[Cache.TAGS] = dependencies[Cache.TAGS]

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

					result[Cache.FILES] = files
					fn(null, result)
				else
					async.eachSeries(dependencies[Cache.FILES], (file, cb) ->
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
							fn(err, null)
						else
							result[Cache.FILES] = files
							fn(null, result)
					)

				result[Cache.FILES] = files

			else
				fn(null, result)

		else
			fn(null, result)


module.exports = Storage