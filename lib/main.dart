import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/listing/presentation/providers/listing_provider.dart';
import 'injection_container.dart' as di;
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await EasyLocalization.ensureInitialized();
  await di.init();

  runApp(
    EasyLocalization(
      supportedLocales: [
        Locale('en'), // English
      ],
      path: 'assets/translations',
      fallbackLocale: Locale('en'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => di.sl<AuthProvider>()),
          ChangeNotifierProvider(create: (_) => di.sl<ListingProvider>()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Localization Hooks
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      title: 'Dr. Pasumai',
      theme: ThemeData(primarySwatch: Colors.green),

      home: const SplashScreen(),
    );
  }
}
