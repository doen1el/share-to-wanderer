import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_to_wanderer/view_models/homepage_view_model.dart';

class CredentialsForm extends StatefulWidget {
  const CredentialsForm({super.key});

  @override
  CredentialsFormState createState() => CredentialsFormState();
}

class CredentialsFormState extends State<CredentialsForm> {
  late TextEditingController domainController;
  late TextEditingController usernameController;
  late TextEditingController passwordController;
  bool useHttps = false;
  bool isInitialized = false;
  bool isTesting = false;
  late Color buttonColor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        buttonColor = Theme.of(context).buttonTheme.colorScheme!.primary;
      });
    });
  }

  /// Load initial values from SharedPreferences
  ///
  /// Parameters:
  ///
  /// - `viewModel`: The HomePageViewModel
  Future<Map<String, dynamic>> _loadInitialValues(
    HomePageViewModel viewModel,
  ) async {
    String domain = await viewModel.getDomain();
    String username = await viewModel.getUsername();
    String password = await viewModel.getPassword();
    bool useHttps = await viewModel.getUseHttps();
    return {
      'domain': domain,
      'username': username,
      'password': password,
      'useHttps': useHttps,
    };
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomePageViewModel>();

    if (!isInitialized) {
      return FutureBuilder<Map<String, dynamic>>(
        future: _loadInitialValues(viewModel),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildPlaceholder();
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else {
            final initialValues = snapshot.data!;
            domainController = TextEditingController(
              text: initialValues['domain'],
            );
            usernameController = TextEditingController(
              text: initialValues['username'],
            );
            passwordController = TextEditingController(
              text: initialValues['password'],
            );
            useHttps = initialValues['useHttps'];
            isInitialized = true;

            return _buildForm(viewModel);
          }
        },
      );
    } else {
      return _buildForm(viewModel);
    }
  }

  /// Build a placeholder widget
  Widget _buildPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        height: 312,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8.0,
              spreadRadius: 2.0,
            ),
          ],
        ),
        padding: const EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  /// Build the form widget
  ///
  /// Parameters:
  ///
  /// - `viewModel`: The HomePageViewModel
  Widget _buildForm(HomePageViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8.0,
              spreadRadius: 2.0,
            ),
          ],
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            _buildTextField(
              controller: domainController,
              labelText: 'Domain / IP:PORT',
              hintText: 'wanderer.example.com',
              onChanged: (value) => viewModel.setDomain(value),
            ),
            _buildTextField(
              controller: usernameController,
              labelText: 'Username',
              hintText: 'admin',
              onChanged: (value) => viewModel.setUsername(value),
            ),
            _buildTextField(
              controller: passwordController,
              labelText: 'Password',
              hintText: 'password',
              obscureText: true,
              onChanged: (value) => viewModel.setPassword(value),
            ),
            _buildHttpsAndTestButtonRow(viewModel),
          ],
        ),
      ),
    );
  }

  /// Build a text field widget
  ///
  /// Parameters:
  ///
  /// - `controller`: The TextEditingController
  /// - `labelText`: The label text
  /// - `hintText`: The hint text
  /// - `obscureText`: Whether the text should be obscured
  /// - `onChanged`: The function to call when the text changes
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    bool obscureText = false,
    required Function(String) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: labelText,
          labelStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          hintText: hintText,
        ),
        onChanged: onChanged,
      ),
    );
  }

  /// Build a row with a switch and a test button
  ///
  /// Parameters:
  ///
  /// - `viewModel`: The HomePageViewModel
  Widget _buildHttpsAndTestButtonRow(HomePageViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                SizedBox(width: 4),
                Text('HTTPS?', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 10),
                Switch(
                  value: useHttps,
                  onChanged: (value) async {
                    setState(() {
                      useHttps = value;
                    });
                    viewModel.setUseHttps(value);
                  },
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: Size(80, 36), // Set a fixed size for the button
            ),
            onPressed: () async {
              setState(() {
                isTesting = true;
              });
              bool success = await viewModel.testConnection();
              setState(() {
                buttonColor = success ? Colors.lightGreen : Colors.redAccent;
                isTesting = false;
              });
            },
            child: Center(
              child:
                  isTesting
                      ? SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : Text('Test', style: TextStyle(fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
