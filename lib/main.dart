import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_to_wanderer/view_models/homepage_view_model.dart';
import 'package:share_to_wanderer/view_models/main_view_model.dart';
import 'package:share_to_wanderer/views/homepage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomePageViewModel()),
        ChangeNotifierProvider(create: (_) => MainViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize sharing intent
    final mainViewModel = Provider.of<MainViewModel>(context, listen: false);
    mainViewModel.initialiseSharingInten();
  }

  @override
  void dispose() {
    // Dispose sharing intent
    final mainViewModel = Provider.of<MainViewModel>(context, listen: false);
    mainViewModel.disposeSharingIntent();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.lightBlue,
      ),
      dark: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.lightBlue,
      ),
      initial: AdaptiveThemeMode.system,
      builder:
          (theme, dartTheme) => MaterialApp(
            title: 'Share to Wanderer',
            theme: theme,
            darkTheme: dartTheme,
            home: const Homepage(),
          ),
    );
  }
}
