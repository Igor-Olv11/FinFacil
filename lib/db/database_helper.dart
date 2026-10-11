import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transacao.dart';
import '../models/divida.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'minhas_financas.db');
    return openDatabase(path, version: 4, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''CREATE TABLE transacoes(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      descricao TEXT NOT NULL,
      valor REAL NOT NULL,
      tipo TEXT NOT NULL,
      categoria TEXT NOT NULL,
      data TEXT NOT NULL,
      recorrente INTEGER NOT NULL DEFAULT 0,
      status TEXT NOT NULL DEFAULT 'pendente',
      dataPagamento TEXT
    )''');
    await db.execute('''CREATE TABLE dividas(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nome TEXT NOT NULL,
      valorTotal REAL NOT NULL,
      valorPago REAL NOT NULL DEFAULT 0,
      dataVencimento TEXT NOT NULL,
      parcelasTotal INTEGER NOT NULL DEFAULT 1,
      parcelasPagas INTEGER NOT NULL DEFAULT 0,
      categoria TEXT NOT NULL DEFAULT 'Outros',
      taxaJuros REAL NOT NULL DEFAULT 0
    )''');
    await db.execute('''CREATE TABLE pagamentos_divida(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      dividaId INTEGER NOT NULL,
      valor REAL NOT NULL,
      data TEXT NOT NULL
    )''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE transacoes ADD COLUMN status TEXT NOT NULL DEFAULT 'pendente'");
      await db.execute("ALTER TABLE transacoes ADD COLUMN dataPagamento TEXT");
      await db.execute("UPDATE transacoes SET status = 'recebida' WHERE tipo = 'receita'");
      await db.execute("CREATE TABLE IF NOT EXISTS pagamentos_divida(id INTEGER PRIMARY KEY AUTOINCREMENT, dividaId INTEGER NOT NULL, valor REAL NOT NULL, data TEXT NOT NULL)");
    }
    if (oldVersion < 4) {
      // Remove the old credit-card feature and its persisted data.
      await db.execute('DROP TABLE IF EXISTS pagamentos_fatura');
      await db.execute('DROP TABLE IF EXISTS compras_cartao');
      await db.execute('DROP TABLE IF EXISTS cartoes_credito');
    }
  }

  Future<int> inserirTransacao(Transacao t) async => (await database).insert('transacoes', t.toMap());
  Future<int> atualizarTransacao(Transacao t) async => (await database).update('transacoes', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
  Future<int> excluirTransacao(int id) async => (await database).delete('transacoes', where: 'id = ?', whereArgs: [id]);

  Future<List<Transacao>> listarTransacoes({TipoTransacao? tipo}) async {
    final db = await database;
    final maps = await db.query('transacoes', where: tipo == null ? null : 'tipo = ?', whereArgs: tipo == null ? null : [tipo == TipoTransacao.receita ? 'receita' : 'despesa'], orderBy: 'data DESC');
    return maps.map(Transacao.fromMap).toList();
  }

  Future<int> inserirDivida(Divida d) async => (await database).insert('dividas', d.toMap());
  Future<int> atualizarDivida(Divida d) async => (await database).update('dividas', d.toMap(), where: 'id = ?', whereArgs: [d.id]);
  Future<int> excluirDivida(int id) async {
    final db = await database;
    await db.delete('pagamentos_divida', where: 'dividaId = ?', whereArgs: [id]);
    return db.delete('dividas', where: 'id = ?', whereArgs: [id]);
  }
  Future<List<Divida>> listarDividas() async => (await database).query('dividas', orderBy: 'dataVencimento ASC').then((maps) => maps.map(Divida.fromMap).toList());

  Future<int> inserirPagamentoDivida(PagamentoDivida p) async => (await database).insert('pagamentos_divida', p.toMap());
  Future<PagamentoDivida?> ultimoPagamentoDivida(int dividaId) async {
    final rows = await (await database).query('pagamentos_divida', where: 'dividaId = ?', whereArgs: [dividaId], orderBy: 'data DESC, id DESC', limit: 1);
    return rows.isEmpty ? null : PagamentoDivida.fromMap(rows.first);
  }
  Future<void> excluirPagamentoDivida(int id) async { await (await database).delete('pagamentos_divida', where: 'id = ?', whereArgs: [id]); }
  Future<List<PagamentoDivida>> listarPagamentosDivida(int dividaId) async => (await database).query('pagamentos_divida', where: 'dividaId = ?', whereArgs: [dividaId], orderBy: 'data DESC').then((m) => m.map(PagamentoDivida.fromMap).toList());
}
