require('./lib/Cache');

require('./lib/Storage/Sync/Storage');
require('./lib/Storage/Async/Storage');

require('./lib/Storage/Sync/FileStorage');
require('./lib/Storage/Sync/BrowserLocalStorage');
require('./lib/Storage/Sync/DevNullStorage');
require('./lib/Storage/Sync/MemoryStorage');
require('./lib/Storage/Async/DevNullStorage');
require('./lib/Storage/Async/MemoryStorage');
require('./lib/Storage/Async/FileStorage');
require('./lib/Storage/Async/RedisStorage');