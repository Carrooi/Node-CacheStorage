Cache = require 'cache-storage'
Storage = require 'cache-storage/lib/Storage/Sync/Storage'

moment = require 'moment'

storage = null

describe 'SyncStorage', ->

	beforeEach( ->
		storage = (new Cache(new Storage)).storage
	)

	describe '#verify()', ->

		it 'should just return true', ->
			expect(storage.verify('random variable')).to.be.true

		it 'should return false if meta expired', ->
			expect(storage.verify(expire: (new Date).getTime() - 200)).to.be.false

		it 'should return false if dependent meta expired', ->
			storage.findMeta = -> return {expire: (new Date).getTime() - 200}
			expect(storage.verify(items: ['test'])).to.be.false

		it 'should return false if file was changed', (done) ->
			files = {}
			files[__filename] = window.require.getStats(__filename).mtime.getTime()
			meta = {files: files}

			setTimeout( ->
				expect(storage.verify(meta)).to.be.true
				changeFile(__filename)
				expect(storage.verify(meta)).to.be.false
				done()
			, 100)

	describe '#parseDependencies()', ->

		it 'should return empty object for unknown type of dependencies', ->
			expect(storage.parseDependencies('random variable')).to.be.eql({})

		it 'should add priority into dependencies', ->
			expect(storage.parseDependencies(priority: 100)).to.be.eql(priority: 100)

		it 'should add tags into dependencies', ->
			expect(storage.parseDependencies(tags: ['comment', 'article'])).to.be.eql(tags: ['comment', 'article'])

		it 'should add dependent item into dependencies', ->
			expect(storage.parseDependencies(items: ['first', 'second'])).to.be.eql(items: [97440432, -906279820])

		it 'should add date from string into dependencies', ->
			expect(storage.parseDependencies(expire: '2014-01-14 20:10')).to.be.eql(expire: 1389726600000)

		it 'should add file into dependencies', ->
			files = {}
			files[__filename] = window.require.getStats(__filename).mtime.getTime()
			expect(storage.parseDependencies(files: [__filename])).to.be.eql(files: files)