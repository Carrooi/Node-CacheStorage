Cache = require 'cache-storage'
Storage = require 'cache-storage/lib/Storage/Async/Storage'

moment = require 'moment'

storage = null

describe 'AsyncStorage', ->

	beforeEach( ->
		storage = (new Cache(new Storage)).storage
	)

	describe '#verify()', ->

		it 'should just return true', (done) ->
			storage.verify('random variable', (state) ->
				expect(state).to.be.true
				done()
			)

		it 'should return false if meta expired', (done) ->
			storage.verify(expire: (new Date).getTime() - 200, (state) ->
				expect(state).to.be.false
				done()
			)

		it 'should return false if dependent meta expired', (done) ->
			storage.findMeta = (key, fn) -> fn({expire: (new Date).getTime() - 200})
			storage.verify(items: ['test'], (state) ->
				expect(state).to.be.false
				done()
			)

		it 'should return false if file was changed', (done) ->
			files = {}
			files[__filename] = window.require.getStats(__filename).mtime.getTime()
			meta = {files: files}

			setTimeout( ->
				storage.verify(meta, (state) ->
					expect(state).to.be.true

					stats = window.require.getStats(__filename)
					oldStats = {}
					oldStats[__filename] = stats
					newStats = {}
					newStats[window.require.resolve(__filename)] =
						atime: stats.atime.getTime()
						mtime: (new Date(stats.mtime.getTime())).setHours(stats.mtime.getHours() + 1)
						ctime: stats.ctime.getTime()
					window.require.__setStats(newStats)

					storage.verify(meta, (state) ->
						expect(state).to.be.false
						done()
					)
				)
			, 100)

	describe '#parseDependencies()', ->

		it 'should return empty object for unknown type of dependencies', (done) ->
			storage.parseDependencies('random variable', (dependencies) ->
				expect(dependencies).to.be.eql({})
				done()
			)

		it 'should add priority into dependencies', (done) ->
			storage.parseDependencies(priority: 100, (dependencies) ->
				expect(dependencies).to.be.eql(priority: 100)
				done()
			)

		it 'should add tags into dependencies', (done) ->
			storage.parseDependencies(tags: ['comment', 'article'], (dependencies) ->
				expect(dependencies).to.be.eql(tags: ['comment', 'article'])
				done()
			)

		it 'should add dependent item into dependencies', (done) ->
			storage.parseDependencies(items: ['first', 'second'], (dependencies) ->
				expect(dependencies).to.be.eql(items: [97440432, -906279820])
				done()
			)

		it 'should add date from string into dependencies', (done) ->
			storage.parseDependencies(expire: '2014-01-14 20:10', (dependencies) ->
				expect(dependencies).to.be.eql(expire: 1389726600000)
				done()
			)

		it 'should add file into dependencies', (done) ->
			files = {}
			files[__filename] = window.require.getStats(__filename).mtime.getTime()
			storage.parseDependencies(files: [__filename], (dependencies) ->
				expect(dependencies).to.be.eql(files: files)
				done()
			)