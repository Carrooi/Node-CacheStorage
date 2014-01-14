
FileStorage = require 'cache-storage/Storage/FileSyncStorage'

describe 'FileSyncStorage', ->

	describe '#constructor()', ->
		it 'should throw an error on browser', ->
			expect( -> new FileStorage ).to.throw(Error)