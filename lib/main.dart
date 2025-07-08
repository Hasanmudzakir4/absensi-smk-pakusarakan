import 'package:absensi_smk_pakusarakan/controllers/auth_controller.dart';
import 'package:absensi_smk_pakusarakan/routes/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi format tanggal lokal Indonesia
  await initializeDateFormatting('id_ID', null);

  // ———————— FIREBASE INITIALIZATION ————————

  // 1) Default app
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // 2) Secondary app (dipakai misalnya untuk pembuatan akun siswa terpisah)
  final hasSecondary = Firebase.apps.any((app) => app.name == 'SecondaryApp');
  if (!hasSecondary) {
    await Firebase.initializeApp(
      name: 'SecondaryApp',
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // // ———————— APP CHECK (Web Only) ————————
  // if (kIsWeb) {
  //   final recaptchaKey = '6LfV4nArAAAAAKVTG3iy5YmJQuiqDejwmFReUO_c';

  //   try {
  //     await FirebaseAppCheck.instance.activate(
  //       webProvider: ReCaptchaV3Provider(recaptchaKey),
  //     );
  //     await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
  //   } catch (e) {
  //     if (e.toString().contains('already-initialized')) {
  //       log('AppCheck already initialized — skipped.');
  //     } else {
  //       log('AppCheck error: $e');
  //     }
  //   }
  // }

  // ———————— RUN APP ————————
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final auth = AuthController();
            if (FirebaseAuth.instance.currentUser != null) {
              auth.loadUserData();
            }
            return auth;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final initialRoute = kIsWeb ? '/login-admin' : '/splash';

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      initialRoute: initialRoute,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
