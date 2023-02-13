import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(
      ignoreSsl: true,
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
    IsolateNameServer.registerPortWithName(
        ReceivePort().sendPort, 'downloader_send_port');
    ReceivePort().listen((dynamic data) {
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];
      if (kDebugMode) {
        print("Download progress: $progress%");
      }
      if (status == DownloadTaskStatus.complete) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Download $id completed!"),
        ));
      }
    });
    FlutterDownloader.registerCallback((id, status, progress) {
      final SendPort? send =
          IsolateNameServer.lookupPortByName('downloader_send_port');
      send?.send([id, status, progress]);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        floatingActionButton: Row(
          children: [
            Spacer(),
            FloatingActionButton(
              child: Icon(Icons.refresh),
              onPressed: () {
                InAppBrowser.openWithSystemBrowser(
                    url: Uri.parse('http://192.168.4.1/downloadFile.html'));
              },
            ),
            SizedBox(width: 30),
            FloatingActionButton(
              child: const Icon(Icons.download),
              onPressed: () async {
                final taskId = await FlutterDownloader.enqueue(
                    headers: {
                      HttpHeaders.connectionHeader: 'keep-alive',
                      'Content-Disposition':
                      'Content-Disposition: attachment; filename=prueba.txt'
                    },
                    fileName: 'prueba.txt',
                    url: 'http://192.168.4.1/downloadFile.html',
                    savedDir: (await getExternalStorageDirectory())!.path,
                timeout: 300000,
                showNotification: true,
                saveInPublicStorage: true,

                // show download progress in status bar (for Android)
                openFileFromNotification:
                true, // click on notification to open downloaded file (for Android)
                );
              },
            ),
          ],
        ),
        appBar: AppBar(
          title: const Text('InAppWebView Example'),
        ),
        body: Column(children: <Widget>[
          Expanded(
              child: InAppWebView(
            key: GlobalKey(),
            initialUrlRequest: URLRequest(
                url: Uri.parse('http://192.168.4.1/downloadFile.html')),
            // initialHeaders: {},
            initialOptions: InAppWebViewGroupOptions(
              android: AndroidInAppWebViewOptions(
                safeBrowsingEnabled: false,
                useHybridComposition: true,
                geolocationEnabled: true,
                disableDefaultErrorPage: false,
                // useHybridComposition: true,
                supportMultipleWindows: false,
                cacheMode: AndroidCacheMode.LOAD_DEFAULT,
              ),
              crossPlatform: InAppWebViewOptions(
                clearCache: true,
                javaScriptEnabled: true,
                javaScriptCanOpenWindowsAutomatically: true,
                useOnDownloadStart: true,
                useShouldOverrideUrlLoading: true,
                mediaPlaybackRequiresUserGesture: false,
                horizontalScrollBarEnabled: false,
                allowFileAccessFromFileURLs: true,
              ),
            ),
            onWebViewCreated: (controller) {
              webView = controller;
            },
            onLoadStart: (_, __) async {
              print('----> On Load Start');
            },
            onLoadStop: (_, __) {
              print('----> On Load Stop');
            },

            onDownloadStartRequest: (controller, url) async {
              var hasStoragePermission = await Permission.storage.isGranted;
              if (!hasStoragePermission) {
                final status = await Permission.storage.request();
                hasStoragePermission = status.isGranted;
              }
              print("onDownloadStart $url");
              final taskId = await FlutterDownloader.enqueue(
                headers: {
              HttpHeaders.connectionHeader: 'keep-alive',
              'Content-Disposition':
                  'Content-Disposition: attachment; filename=prueba.txt'
            },
                fileName: 'prueba.txt',
                url: url.toString(),
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
        ]),
      ),
    );
  }
}
