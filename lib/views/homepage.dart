import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_to_wanderer/view_models/main_view_model.dart';
import 'package:share_to_wanderer/views/widgets/credential_form.dart';
import 'package:permission_handler/permission_handler.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  Future<void> _pickAndUploadFiles(BuildContext context) async {
    // Request storage permissions

    final result = await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result != null) {
      final viewModel = context.read<MainViewModel>();
      for (var file in result.files) {
        if (file.path != null) {
          await viewModel.uploadGpx(file.path!);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Share to Wanderer')),
      body: Column(
        children: <Widget>[SizedBox(height: 100), CredentialsForm()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _pickAndUploadFiles(context),
        tooltip: 'Upload GPX',
        child: Icon(Icons.upload),
      ),
    );
  }
}
