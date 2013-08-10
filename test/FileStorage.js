(function () {

	var should = require('should');

	var FileStorage = require('../lib/Storage/FileStorage');

	describe('FileStorage', function() {

		describe('#constructor()', function() {

			it('should throw an error if path does not exists', function() {
				(function() {
					new FileStorage(__dirname + '/data/unknown');
				}).should.throw();
			});

			it('should throw an error if path is not directory', function() {
				(function() {
					new FileStorage(__dirname + '/data/file');
				}).should.throw();
			});

		});

	});

})();