import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(
      debug: true // optional: set false to disable printing logs to console
      );
  await Permission.storage.request();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  InAppWebViewController? webView;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('InAppWebView Example'),
        ),
        body: Container(
            child: Column(children: <Widget>[
          Expanded(
              child: InAppWebView(

            initialUrlRequest: URLRequest(url: Uri.parse('http://192.168.4.1/confDownload.html')),
            // initialHeaders: {},
            initialOptions: InAppWebViewGroupOptions(

              android: AndroidInAppWebViewOptions(
                disableDefaultErrorPage: false,
                // useHybridComposition: true,
                supportMultipleWindows: false,
                cacheMode: AndroidCacheMode.LOAD_DEFAULT,
              ),
              crossPlatform: InAppWebViewOptions(

                  useOnDownloadStart: true,
                  javaScriptCanOpenWindowsAutomatically: true,
                  javaScriptEnabled: true,
                  useShouldOverrideUrlLoading: true),
            ),
            onWebViewCreated: (InAppWebViewController controller) {
              webView = controller;
            },
            onLoadStart: (_, __) async {
              print('---->');
            },
            onLoadStop: (_, __) {
              // FlutterNativeSplash.remove();
            },

            onDownloadStartRequest: (controller, url) async {
              print("onDownloadStart $url");
              final taskId = await FlutterDownloader.enqueue(
                headers: {
                  'Content-Disposition' : 'attachment; filename="filename.jpg"'
                },
                //fileName: 'prueba.txt',
                url: 'http://192.168.4.1/download.html?inf=0&sup=300',
                savedDir: (await getExternalStorageDirectory())!.path,
                timeout: 300000,
                showNotification: true,
                saveInPublicStorage: true,
                // show download progress in status bar (for Android)
                openFileFromNotification:
                    true, // click on notification to open downloaded file (for Android)
              );
            },
          ))
        ])),
      ),
    );
  }
}
