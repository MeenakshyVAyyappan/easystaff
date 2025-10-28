import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:eazystaff/services/auth_service.dart';
import 'package:eazystaff/services/logging_service.dart';
import 'package:eazystaff/login.dart';
import 'package:eazystaff/home.dart'; // contains HomeScreen

Future<void> main() async {
  // Set up global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    LoggingService.critical(
      'Flutter Framework Error: ${details.exception}',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  runZonedGuarded(() async {
    try {
      LoggingService.logAppStart();
      LoggingService.logBuildInfo();

      WidgetsFlutterBinding.ensureInitialized();

      // Add error handling for AuthService.hydrate()
      try {
        await AuthService.hydrate(); // load cached user if any
        LoggingService.info('AuthService hydration completed successfully');
      } catch (e, stackTrace) {
        LoggingService.error(
          'AuthService.hydrate() failed',
          error: e,
          stackTrace: stackTrace,
        );
        // Continue with app initialization even if hydration fails
      }

      LoggingService.logAppReady();
      runApp(const MyApp());
    } catch (e, stackTrace) {
      LoggingService.critical(
        'Main initialization error',
        error: e,
        stackTrace: stackTrace,
      );
      // Run a minimal error app
      runApp(ErrorApp(error: e.toString()));
    }
  }, (error, stack) {
    LoggingService.critical(
      'Uncaught zone error',
      error: error,
      stackTrace: stack,
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final start = AuthService.currentUser == null ? '/login' : '/home';
    LoggingService.info('App starting with initial route: $start');

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: start,
      routes: {
        '/login': (context) => const LoginPage(),
        '/home':  (context) => const HomeScreen(),
      },
      // Add error handling for route generation
      onGenerateRoute: (settings) {
        LoggingService.logNavigation('unknown', settings.name ?? 'null');
        return null; // Let the default routing handle it
      },
      // Add error widget builder
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          if (kDebugMode) {
            return ErrorWidget(errorDetails.exception);
          }
          return Container(
            color: Colors.white,
            child: const Center(
              child: Text(
                'Something went wrong!',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
          );
        };
        return child ?? Container();
      },
    );
  }
}

// Error app to show when main app fails to initialize
class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'App Initialization Failed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error: $error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Try to restart the app
                    main();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
