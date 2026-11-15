import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'data/local_store.dart';
import 'state/providers.dart';
import 'ui/screens/auth_screen.dart';
import 'ui/screens/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = LocalStore();
  await store.open();
  runApp(ProviderScope(
    overrides: [localStoreProvider.overrideWithValue(store)],
    child: const EncoreApp(),
  ));
}

class EncoreApp extends ConsumerWidget {
  const EncoreApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // a saved session opens straight into the app, even with no internet
    final signedIn = ref.watch(authProvider) != null;
    return MaterialApp(
      title: 'Encore',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: signedIn ? const HomeShell() : const AuthScreen(),
    );
  }
}

ThemeData _theme(Brightness brightness) {
  // stage-light purple with a warm pink accent
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF7C3AED),
    tertiary: const Color(0xFFEC4899),
    brightness: brightness,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  final radius = BorderRadius.circular(16);
  return base.copyWith(
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme),
    appBarTheme: const AppBarTheme(centerTitle: false, scrolledUnderElevation: 0),
    cardTheme: CardThemeData(elevation: 0, color: scheme.surfaceContainerHigh, shape: RoundedRectangleBorder(borderRadius: radius)),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
      border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: scheme.primary, width: 2)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(shape: const StadiumBorder()),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
    }),
  );
}
