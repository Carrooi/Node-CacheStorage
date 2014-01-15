expect = require('chai').expect

Cache = require '../../../../../lib/Cache'
Storage = require '../../../../../lib/Storage/Sync/Storage'

moment = require 'moment'

cache = null
storage = null
fs = null

describe 'SyncStorage', ->

	beforeEach( ->
		storage = new Storage
		cache = new Cache(storage)
		fs = Cache.mockFs(
			'file': ''
		)
	)

	afterEach( ->
		Cache.restoreFs()
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
			meta = {files: {'/file': fs.statSync('/file').mtime.getTime()}}
			setTimeout( ->
				expect(storage.verify(meta)).to.be.true
				fs.writeFileSync('/file', '')
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
			expect(storage.parseDependencies(items: ['first', 'second'])).to.be.eql(items: [cache.generateKey('first'), cache.generateKey('second')])

		it 'should add date from string into dependencies', ->
			time = '2014-01-14 20:10'
			expect(storage.parseDependencies(expire: time)).to.be.eql(expire: moment(time, Cache.TIME_FORMAT).valueOf())

		it 'should add file into dependencies', ->
			time = fs.statSync('/file').mtime.getTime()
			expect(storage.parseDependencies(files: ['/file'])).to.be.eql(files: {'/file': time})