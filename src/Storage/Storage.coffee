fs = require 'fs'
moment = require 'moment'
Cache = require '../Cache'

class Storage


	cache: null


	read: (key) ->
		throw new Error 'Cache storage: read method is not implemented.'


	write: (key, data, dependencies = {}) ->
		throw new Error 'Cache storage: write method is not implemented.'


	remove: (key) ->
		throw new Error 'Cache storage: remove method is not implemented.'


	clean: (conditions) ->
		throw new Error 'Cache storage: clean method is not implemented'


	getMeta: ->
		throw new Error 'Cache storage: getMeta method is not implemented'


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
				for file, time of meta[Cache.FILES]
					if (new Date(fs.statSync(file).mtime)).getTime() != time then return false

			if typeof meta[Cache.EXPIRE] != 'undefined'
				if moment().valueOf() >= meta[Cache.EXPIRE] then return false

			if typeof meta[Cache.ITEMS] != 'undefined'
				for item in meta[Cache.ITEMS]
					item = @findMeta(item)
					if (item == null) || (item != null && @verify(item) == false) then return false

		return true


module.exports = Storage
