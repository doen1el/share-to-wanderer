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
        ChangeNotifierProvider(create: (_) => HomePageViewModel()..getTheme()),
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
  late bool _themeMode;

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
    return ChangeNotifierProvider(
      create: (context) => HomePageViewModel(),
      child: Consumer<HomePageViewModel>(
        builder: (context, viewModel, child) {
          return MaterialApp(
            title: 'Share to Wanderer',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.lightBlue,
                brightness: Brightness.light,
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.lightBlue,
                brightness: Brightness.dark,
              ),
            ),
            themeMode: viewModel.themeMode,
            home: const Homepage(),
          );
        },
      ),
    );
  }
}
