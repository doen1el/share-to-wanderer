import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:share_to_wanderer/view_models/homepage_view_model.dart';
import 'package:share_to_wanderer/view_models/main_view_model.dart';
import 'package:share_to_wanderer/views/widgets/credential_form.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_to_wanderer/views/widgets/text_display.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  /// Pick and upload GPX files
  /// Parameters:
  ///
  /// - `context`: The BuildContext
  Future<void> _pickAndUploadFiles(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result != null) {
      // ignore: use_build_context_synchronously
      final viewModel = context.read<MainViewModel>();
      viewModel.isLoading.value = true;
      for (var file in result.files) {
        if (file.path != null) {
          await viewModel.uploadGpx(file.path!);
        } else {
          Fluttertoast.showToast(
            msg: "No file picked",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        }
      }
      viewModel.isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomePageViewModel>();
    final mainViewModel = context.watch<MainViewModel>();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: ValueListenableBuilder<bool>(
          valueListenable: mainViewModel.isLoading,
          builder: (context, isLoading, child) {
            return AppBar(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Share to Wanderer',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: viewModel.isDarkTheme,
                        builder: (context, isDarkTheme, child) {
                          return IconButton(
                            onPressed: () async {
                              await viewModel.setTheme(!isDarkTheme);
                            },
                            icon: Icon(
                              isDarkTheme ? Icons.dark_mode : Icons.light_mode,
                            ),
                            tooltip: "Toggle theme",
                          );
                        },
                      ),
                      IconButton(
                        onPressed: () async {
                          final Uri url = Uri.parse(
                            'https://github.com/doen1el/share-to-wanderer/issues/new',
                          );
                          if (!await launchUrl(url)) {
                            throw Exception('Could not launch $url');
                          }
                        },
                        icon: Icon(Icons.bug_report_rounded),
                        tooltip: "Report a bug",
                      ),
                    ],
                  ),
                ],
              ),
              backgroundColor: isLoading ? Colors.black54 : null,
            );
          },
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: <Widget>[
                SizedBox(height: 10),
                TextDisplay(
                  text:
                      "Enter your wanderer credentials below. Then you can share your GPX files to this app and they will be uploaded to your wanderer instance.",
                ),
                SizedBox(height: 30),
                CredentialsForm(),
                SizedBox(height: 30),

                TextDisplay(
                  text:
                      "You can also upload GPX files manually by clicking the button below.",
                ),
              ],
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: mainViewModel.isLoading,
            builder: (context, isLoading, child) {
              if (isLoading) {
                return Container(
                  color: Colors.black54,
                  child: Center(child: CircularProgressIndicator()),
                );
              } else {
                return SizedBox.shrink();
              }
            },
          ),
        ],
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: mainViewModel.isLoading,
        builder: (context, isLoading, child) {
          return FloatingActionButton(
            onPressed: isLoading ? null : () => _pickAndUploadFiles(context),
            tooltip: "Upload GPX files",
            backgroundColor: isLoading ? Colors.grey : null,
            child: Icon(Icons.upload_rounded),
          );
        },
      ),
    );
  }
}
