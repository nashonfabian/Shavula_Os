import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('biashara_mfukoni.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3, // 2: email/password_hash | 3: locations, Products.sku
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Kwa wale waliosakinisha app kabla ya sasa - ongeza columns mpya
      // bila kupoteza data waliyokuwa nayo tayari.
      await db.execute('ALTER TABLE users ADD COLUMN email TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN password_hash TEXT');
      await db.execute(
          'CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email ON users(email)');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE Products ADD COLUMN sku TEXT');
      await _createLocationsTable(db);
    }
  }

  Future<void> _createLocationsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS locations (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        region TEXT,
        created_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Table: Loans
    await db.execute('''
      CREATE TABLE Loans (
        id INTEGER PRIMARY KEY,
        created_at TEXT,
        amount_paid REAL,
        customer_id TEXT,
        customer_location TEXT,
        customer_name TEXT,
        customer_phone TEXT,
        daily_payment REAL,
        due_date TEXT,
        initial_amount REAL,
        product_name TEXT,
        remaining_balance REAL,
        status TEXT,
        supplier_id TEXT,
        total_amount REAL,
        start_date TEXT,
        show_daily_payment INTEGER,
        show_due_date INTEGER,
        customer TEXT,
        is_synced INTEGER DEFAULT 0,
        updated_at TEXT
      )
    ''');

    // 2. Table: Orders
    await db.execute('''
      CREATE TABLE Orders (
        id INTEGER PRIMARY KEY,
        created_at TEXT,
        customer_name TEXT,
        customer_phone TEXT,
        customer_area TEXT,
        product_name TEXT,
        product_url TEXT,
        note TEXT,
        price INTEGER,
        status TEXT,
        reason TEXT,
        rejection_note TEXT,
        status2 TEXT,
        supplier TEXT,
        product_id REAL,
        quantity REAL,
        product_url2 TEXT,
        matched_supplier TEXT,
        admin TEXT,
        is_synced INTEGER DEFAULT 0,
        updated_at TEXT
      )
    ''');

    // 3. Table: Payments
    await db.execute('''
      CREATE TABLE Payments (
        id INTEGER PRIMARY KEY,
        created_at TEXT,
        amount_payment REAL,
        supplier_id TEXT,
        payment_date TEXT,
        loan_id REAL,
        payment_customer_name TEXT,
        loan_payment REAL,
        customer_id TEXT,
        is_synced INTEGER DEFAULT 0,
        updated_at TEXT
      )
    ''');

    // 4. Table: Products
    await db.execute('''
      CREATE TABLE Products (
        id INTEGER PRIMARY KEY,
        created_at TEXT,
        category TEXT,
        colour_nakshi TEXT,
        image_url TEXT,
        is_main INTEGER,
        is_top INTEGER,
        is_trending INTEGER,
        made_where TEXT,
        materials TEXT,
        name TEXT,
        pre_name TEXT,
        price INTEGER,
        product_description TEXT,
        product_condition TEXT,
        ubora TEXT,
        warranty TEXT,
        supplier_email TEXT,
        similarity_product TEXT,
        search_category TEXT,
        sku TEXT,
        is_synced INTEGER DEFAULT 0,
        updated_at TEXT
      )
    ''');

    // 5. Table: Seller_listing
    await db.execute('''
      CREATE TABLE Seller_listing (
        id INTEGER PRIMARY KEY,
        created_at TEXT,
        product_id INTEGER,
        supplier_name TEXT,
        area TEXT,
        cash_price REAL,
        loan_price REAL,
        kianzio REAL,
        daily_payment REAL,
        is_active INTEGER,
        supplier_email TEXT,
        admin_email TEXT,
        is_synced INTEGER DEFAULT 0,
        updated_at TEXT
      )
    ''');

    // 6. Table: users (email + password_hash zimeongezwa kwa ajili ya offline login)
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        supplier_id TEXT,
        full_name TEXT,
        email TEXT,
        password_hash TEXT,
        phone_number TEXT,
        business_name TEXT,
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');
    await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email ON users(email)');

    // 7. Table: locations (au product_locations)
    await db.execute('''
      CREATE TABLE product_locations (
        id TEXT PRIMARY KEY,
        product_id TEXT,
        location_name TEXT,
        created_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // 8. Table: locations (inalingana na Supabase: id, name, region)
    await _createLocationsTable(db);
  }

  // Helper Methods
  Future<int> insertOrUpdate(String tableName, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert(
      tableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedRecords(String tableName) async {
    final db = await instance.database;
    return await db.query(
      tableName,
      where: 'is_synced = ?',
      whereArgs: [0],
    );
  }

  Future<int> markAsSynced(String tableName, dynamic id) async {
    final db = await instance.database;
    return await db.update(
      tableName,
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getLocalDataBySupplier(
    String tableName,
    String columnName,
    String supplierEmail,
  ) async {
    final db = await instance.database;
    return await db.query(
      tableName,
      where: '$columnName = ?',
      whereArgs: [supplierEmail],
    );
  }

  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final db = await instance.database;
    if (query.trim().isEmpty) return [];

    return await db.rawQuery('''
      SELECT * FROM Products
      WHERE name LIKE ? OR category LIKE ? OR search_category LIKE ?
      LIMIT 20
    ''', ['%$query%', '%$query%', '%$query%']);
  }

  // ---------- Mbinu mpya kwa ajili ya AUTH (offline-first) ----------

  /// Tafuta mtumiaji kwa email - hutumika wakati wa offline login
  /// na pia kuangalia kama email tayari imeshatumika kabla ya register.
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await instance.database;
    final results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first;
  }

  /// Tafuta mtumiaji kwa id - hutumika kurudisha session iliyohifadhiwa
  /// (SharedPreferences) bila kumlazimu mtumiaji kuingia tena.
  Future<Map<String, dynamic>?> getUserById(String id) async {
    final db = await instance.database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first;
  }

  /// Takwimu za Dashibodi (Mtoa Bidhaa home page):
  /// - pendingRequests: Loans mpya zenye status = 'pending'
  /// - totalCustomers: idadi ya wateja tofauti wa huyu supplier
  /// - overdueJobs: Loans ambazo due_date imepita na bado hazijakamilika
  /// - todayJobs: Loans zenye due_date ya leo
  Future<Map<String, int>> getDashboardStats(String supplierId) async {
    final db = await instance.database;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    final pendingRequests = Sqflite.firstIntValue(await db.rawQuery('''
      SELECT COUNT(*) FROM Loans WHERE supplier_id = ? AND status = 'pending'
    ''', [supplierId])) ?? 0;

    final totalCustomers = Sqflite.firstIntValue(await db.rawQuery('''
      SELECT COUNT(DISTINCT customer_id) FROM Loans WHERE supplier_id = ?
    ''', [supplierId])) ?? 0;

    final overdueJobs = Sqflite.firstIntValue(await db.rawQuery('''
      SELECT COUNT(*) FROM Loans
      WHERE supplier_id = ? AND status != 'completed' AND substr(due_date, 1, 10) < ?
    ''', [supplierId, todayStr])) ?? 0;

    final todayJobs = Sqflite.firstIntValue(await db.rawQuery('''
      SELECT COUNT(*) FROM Loans
      WHERE supplier_id = ? AND substr(due_date, 1, 10) = ?
    ''', [supplierId, todayStr])) ?? 0;

    return {
      'pendingRequests': pendingRequests,
      'totalCustomers': totalCustomers,
      'overdueJobs': overdueJobs,
      'todayJobs': todayJobs,
    };
  }

  Future<void> clearAllTables() async {
    final db = await instance.database;
    final tables = [
      'Loans',
      'Orders',
      'Payments',
      'Products',
      'Seller_listing',
      'users',
      'product_locations',
      'locations'
    ];
    for (var table in tables) {
      await db.delete(table);
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
