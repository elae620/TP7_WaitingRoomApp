import 'local_database_factory_stub.dart'
    if (dart.library.js_interop) 'local_database_factory_web.dart'
    as implementation;

Future<void> initializeLocalDatabaseFactory() =>
    implementation.initializeLocalDatabaseFactory();
