import 'package:logging/logging.dart';

class AppLogger {
  static final Logger _logger = Logger('DetsadApp');

  static void init() {
    // Настройка уровня логирования
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      // Выводим сообщения только если это не продакшн
      // В продакшене можно отключить или отправлять в удаленный сервис
      _logger.info('${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
    });
  }

  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.fine(message, error, stackTrace);
  }

  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.info(message, error, stackTrace);
  }

  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.warning(message, error, stackTrace);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.severe(message, error, stackTrace);
  }
}