expect = require('chai').expect

Cache = require '../../../../../lib/Cache'
Storage = require '../../../../../lib/Storage/Async/Storage'

moment = require 'moment'

cache = null
storage = null
fs = null

describe 'AsyncStorage', ->

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

		it 'should just return true', (done) ->
			storage.verify('random variable', (err, state) ->
				expect(state).to.be.true
				done()
			)

		it 'should return false if meta expired', (done) ->
			storage.verify(expire: (new Date).getTime() - 200, (err, state) ->
				expect(state).to.be.false
				done()
			)

		it 'should return false if dependent meta expired', (done) ->
			storage.findMeta = (key, fn) -> fn(null, {expire: (new Date).getTime() - 200})
			storage.verify(items: ['test'], (err, state) ->
				expect(state).to.be.false
				done()
			)

		it 'should return false if file was changed', (done) ->
			meta = {files: {'/file': fs.statSync('/file').mtime.getTime()}}
			setTimeout( ->
				storage.verify(meta, (err, state) ->
					expect(state).to.be.true
					fs.writeFileSync('/file', '')
					storage.verify(meta, (err, state) ->
						expect(state).to.be.false
						done()
					)
				)
			, 100)

	describe '#parseDependencies()', ->

		it 'should return empty object for unknown type of dependencies', (done) ->
			storage.parseDependencies('random variable', (err, dependencies) ->
				expect(dependencies).to.be.eql({})
				done()
			)

		it 'should add priority into dependencies', (done) ->
			storage.parseDependencies(priority: 100, (err, dependencies) ->
				expect(dependencies).to.be.eql(priority: 100)
				done()
			)

		it 'should add tags into dependencies', (done) ->
			storage.parseDependencies(tags: ['comment', 'article'], (err, dependencies) ->
				expect(dependencies).to.be.eql(tags: ['comment', 'article'])
				done()
			)

		it 'should add dependent item into dependencies', (done) ->
			storage.parseDependencies(items: ['first', 'second'], (err, dependencies) ->
				expect(dependencies).to.be.eql(items: [cache.generateKey('first'), cache.generateKey('second')])
				done()
			)

		it 'should add date from string into dependencies', (done) ->
			time = '2014-01-14 20:10'
			storage.parseDependencies(expire: time, (err, dependencies) ->
				expect(dependencies).to.be.eql(expire: moment(time, Cache.TIME_FORMAT).valueOf())
				done()
			)

		it 'should add file into dependencies', (done) ->
			time = fs.statSync('/file').mtime.getTime()
			storage.parseDependencies(files: ['/file'], (err, dependencies) ->
				expect(dependencies).to.be.eql(files: {'/file': time})
				done()
			)