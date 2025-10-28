import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

class LoggingService {
  static const String _tag = 'EazyStaff';
  
  static void debug(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  static void info(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  static void warning(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  static void critical(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.critical, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  static void _log(
    LogLevel level, 
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final String logTag = tag ?? _tag;
    final String timestamp = DateTime.now().toIso8601String();
    final String levelStr = level.name.toUpperCase();
    
    String logMessage = '[$timestamp] [$levelStr] [$logTag] $message';
    
    if (error != null) {
      logMessage += '\nError: $error';
    }
    
    if (stackTrace != null) {
      logMessage += '\nStack trace:\n$stackTrace';
    }
    
    // Use different logging methods based on level
    switch (level) {
      case LogLevel.debug:
        if (kDebugMode) {
          debugPrint(logMessage);
          developer.log(message, name: logTag, level: 500);
        }
        break;
      case LogLevel.info:
        debugPrint(logMessage);
        developer.log(message, name: logTag, level: 800);
        break;
      case LogLevel.warning:
        debugPrint(logMessage);
        developer.log(message, name: logTag, level: 900);
        break;
      case LogLevel.error:
        debugPrint(logMessage);
        developer.log(message, name: logTag, level: 1000, error: error, stackTrace: stackTrace);
        break;
      case LogLevel.critical:
        debugPrint(logMessage);
        developer.log(message, name: logTag, level: 1200, error: error, stackTrace: stackTrace);
        break;
    }
  }
  
  // Specific logging methods for common scenarios
  static void logAppStart() {
    info('Application starting...');
  }
  
  static void logAppReady() {
    info('Application ready');
  }
  
  static void logNavigation(String from, String to) {
    debug('Navigation: $from -> $to', tag: 'Navigation');
  }
  
  static void logApiCall(String endpoint, {Map<String, dynamic>? params}) {
    String message = 'API Call: $endpoint';
    if (params != null && params.isNotEmpty) {
      message += ' with params: $params';
    }
    debug(message, tag: 'API');
  }
  
  static void logApiResponse(String endpoint, int statusCode, {String? response}) {
    String message = 'API Response: $endpoint - Status: $statusCode';
    if (response != null && kDebugMode) {
      message += '\nResponse: ${response.length > 500 ? '${response.substring(0, 500)}...' : response}';
    }
    debug(message, tag: 'API');
  }
  
  static void logApiError(String endpoint, Object error, {StackTrace? stackTrace}) {
    LoggingService.error('API Error: $endpoint', tag: 'API', error: error, stackTrace: stackTrace);
  }
  
  static void logUserAction(String action, {Map<String, dynamic>? context}) {
    String message = 'User Action: $action';
    if (context != null && context.isNotEmpty) {
      message += ' with context: $context';
    }
    info(message, tag: 'UserAction');
  }
  
  static void logException(String context, Object exception, {StackTrace? stackTrace}) {
    error('Exception in $context', error: exception, stackTrace: stackTrace);
  }
  
  static void logPerformance(String operation, Duration duration) {
    info('Performance: $operation took ${duration.inMilliseconds}ms', tag: 'Performance');
  }
  
  static void logMemoryUsage(String context) {
    if (kDebugMode) {
      // This is a placeholder - in a real app you might want to use a memory profiling library
      debug('Memory check: $context', tag: 'Memory');
    }
  }
  
  static void logDeviceInfo(Map<String, dynamic> deviceInfo) {
    info('Device Info: $deviceInfo', tag: 'Device');
  }
  
  static void logBuildInfo() {
    info('Build Mode: ${kDebugMode ? 'Debug' : 'Release'}', tag: 'Build');
    info('Platform: ${defaultTargetPlatform.name}', tag: 'Build');
  }
}
