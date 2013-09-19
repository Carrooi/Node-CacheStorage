
Cache = require 'cache-storage'

describe 'Cache', ->

	describe '#constructor()', ->
		it 'should throw an error if storage is not an instance of Cache Storage', ->
			expect( -> new Cache(new Array) ).to.throw(Error)