import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/cliente.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'servicos_montador.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE clientes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        sobrenome TEXT NOT NULL,
        endereco TEXT NOT NULL,
        valor REAL NOT NULL,
        dataAgendada INTEGER NOT NULL,
        concluido INTEGER NOT NULL DEFAULT 0,
        dataConclusao INTEGER
      )
    ''');
  }

  // Inserir cliente
  Future<int> inserirCliente(Cliente cliente) async {
    final db = await database;
    return await db.insert('clientes', cliente.toMap());
  }

  // Buscar todos os clientes
  Future<List<Cliente>> buscarTodosClientes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('clientes');
    return List.generate(maps.length, (i) {
      return Cliente.fromMap(maps[i]);
    });
  }

  // Buscar cliente por ID
  Future<Cliente?> buscarClientePorId(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clientes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Cliente.fromMap(maps.first);
    }
    return null;
  }

  // Buscar clientes pendentes (não concluídos)
  Future<List<Cliente>> buscarClientesPendentes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clientes',
      where: 'concluido = ?',
      whereArgs: [0],
      orderBy: 'dataAgendada ASC',
    );
    return List.generate(maps.length, (i) {
      return Cliente.fromMap(maps[i]);
    });
  }

  // Buscar clientes concluídos
  Future<List<Cliente>> buscarClientesConcluidos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clientes',
      where: 'concluido = ?',
      whereArgs: [1],
      orderBy: 'dataConclusao DESC',
    );
    return List.generate(maps.length, (i) {
      return Cliente.fromMap(maps[i]);
    });
  }

  // Atualizar cliente
  Future<int> atualizarCliente(Cliente cliente) async {
    final db = await database;
    return await db.update(
      'clientes',
      cliente.toMap(),
      where: 'id = ?',
      whereArgs: [cliente.id],
    );
  }

  // Deletar cliente
  Future<int> deletarCliente(int id) async {
    final db = await database;
    return await db.delete('clientes', where: 'id = ?', whereArgs: [id]);
  }

  // Marcar cliente como concluído
  Future<int> marcarClienteConcluido(int id) async {
    final db = await database;
    return await db.update(
      'clientes',
      {'concluido': 1, 'dataConclusao': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Buscar clientes por data
  Future<List<Cliente>> buscarClientesPorData(DateTime data) async {
    final db = await database;
    final startOfDay = DateTime(data.year, data.month, data.day);
    final endOfDay = DateTime(data.year, data.month, data.day, 23, 59, 59);

    final List<Map<String, dynamic>> maps = await db.query(
      'clientes',
      where: 'dataAgendada >= ? AND dataAgendada <= ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
      orderBy: 'dataAgendada ASC',
    );
    return List.generate(maps.length, (i) {
      return Cliente.fromMap(maps[i]);
    });
  }

  // Buscar clientes concluídos por período
  Future<List<Cliente>> buscarClientesConcluidosPorPeriodo(
    DateTime inicio,
    DateTime fim,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clientes',
      where: 'concluido = ? AND dataConclusao >= ? AND dataConclusao <= ?',
      whereArgs: [1, inicio.millisecondsSinceEpoch, fim.millisecondsSinceEpoch],
      orderBy: 'dataConclusao ASC',
    );
    return List.generate(maps.length, (i) {
      return Cliente.fromMap(maps[i]);
    });
  }

  // Fechar banco de dados
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
