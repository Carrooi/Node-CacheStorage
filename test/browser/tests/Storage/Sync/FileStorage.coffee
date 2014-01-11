
FileStorage = require 'cache-storage/Storage/FileStorage'

describe 'FileStorage', ->

	describe '#constructor()', ->
		it 'should throw an error on browser', ->
			expect( -> new FileStorage ).to.throw(Error)