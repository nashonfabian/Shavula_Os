import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'helpers/db_helper.dart';
import 'helpers/sync_helper.dart';
import 'home_page.dart'; // <--- Hakikisha hii ipo

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://nmjmfsaelezhccsptkie.supabase.co',
    publishableKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5tam1mc2FlbGV6aGNjc3B0a2llIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUwMzQwMzEsImV4cCI6MjA5MDYxMDAzMX0.Qwwg4rE6ToSHddMXts79IDNln1_7KmOnuj8wyKJDpVI',
  );

  await DatabaseHelper.instance.database;
  SyncHelper.instance.startAutoSync();
  await SyncHelper.instance.syncLocalToCloud();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Biashara Mfukoni',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
      home: const HomePage(), // <--- Onyesha HomePage hapa
    );
  }
}
