import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Importe o core
import 'firebase_options.dart'; // Importe o arquivo gerado
import 'screens/login_page.dart';
import 'screens/traditional_login_page.dart';

Future<void> main() async {
  // Garante que o Flutter está pronto
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase com as configurações da sua plataforma
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Seguro com Firebase',
      theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
      // home: const LoginPage(),
      home: const TraditionalLoginPage(),
    );
  }
}
