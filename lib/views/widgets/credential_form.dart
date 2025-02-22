import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading data'));
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: domainController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Domain / IP:PORT',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                onChanged: (value) async {
                  viewModel.setDomain(value);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Username',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                onChanged: (value) async {
                  viewModel.setUsername(value);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                onChanged: (value) async {
                  viewModel.setPassword(value);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                title: Text('Use HTTPS'),
                trailing: Switch(
                  value: useHttps,
                  onChanged: (value) async {
                    setState(() {
                      useHttps = value;
                    });
                    viewModel.setUseHttps(value);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
