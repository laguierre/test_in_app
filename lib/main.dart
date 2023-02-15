import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_html/html.dart' as html;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(debug: true);
  await Permission.storage.request();
  FlutterDownloader.registerCallback(DownloadClass.callback);
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class DownloadClass {
  static void callback(String id, DownloadTaskStatus status, int progress) {
    print('Download Status: $status');
    print('Download Progress: $progress');
    final SendPort send =
    IsolateNameServer.lookupPortByName('downloader_send_port')!;
    send.send([id, status, progress]);
  }
}

class _MyAppState extends State<MyApp> {
  InAppWebViewController? webView;
  final ReceivePort _port = ReceivePort();
  final JavascriptRuntime jsRuntime = getJavascriptRuntime();

  @override
  void initState() {
    super.initState();
    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];
      setState(() {});
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
            const SizedBox(width: 30),
            FloatingActionButton(
              child: const Icon(Icons.sim_card_download),
              onPressed: () async {
                /*await FileDownloader.downloadFile(
                    url: 'http://192.168.4.1/downloadFile.html',//"http://192.168.4.1/download.html?inf=100&sup=200",
                    name: "Prueba",
                    onDownloadCompleted: (path) {
                      print(path);
                      final File file = File(path);
                      print(file);
                      //This will be the path of the downloaded file
                    });*/

                //String url = 'http://192.168.4.1/download.html?inf=100&sup=200';
                Uri url = Uri(
                    scheme: 'http',
                    path: '192.168.4.1/download.html',
                    queryParameters: {
                      'inf': '0',
                      'sup': '100',
                    });
                // html.window.open(url, '_blank');

                //final bytes = utf8.encode(text);
                //final blob = html.Blob([bytes]);
                //final url = html.Url.createObjectUrlFromBlob(blob);
                final anchor = html.document.createElement('a')
                as html.AnchorElement
                  ..href = "http://192.168.4.1/download.html?inf=100&sup=200"
                  ..style.display = "none"
                  ..download = "some_name.txt"
                  ..innerHtml = "pepe";


                print(anchor.toString());
                var a = anchor.toString();
                html.document.body!.innerHtml = anchor.innerText;
                print('----->Edu said ${html.document.body}');

                anchor.click();
                print('--->Click');
                html.document.body?.children.remove(anchor);
                html.Url.revokeObjectUrl(
                    'http://192.168.4.1/download.html?inf=100&sup=200');

                /*try {
                  String blocJs =
                      await rootBundle.loadString('lib/js/downloadFile.js');
                  print(blocJs);
                  int limInf = 10, limSup = 100;
                  final jsResult = jsRuntime.evaluate("""${blocJs}sendToDownload($limInf, $limSup)""");
                  //final jsResult = jsRuntime.evaluate("""${blocJs}sendToDownload()""");
                  print(jsResult);
                } on PlatformException catch (e) {
                  print('Error JS: ${e.details}');
                }*/
              },
            ),
            const Spacer(),
            FloatingActionButton(
              child: const Icon(Icons.refresh),
              onPressed: () {
                InAppBrowser.openWithSystemBrowser(
                    url: Uri.parse(
                        'http://192.168.4.1/confDownload.html')); //Uri.parse('http://192.168.4.1/downloadFile.html'));http://192.168.4.1/download.html?inf=' + limInf +'&sup=' limSup)
              },
            ),
            const SizedBox(width: 30),
            FloatingActionButton(
              child: const Icon(Icons.download),
              onPressed: () async {
                var hasStoragePermission = await Permission.storage.isGranted;
                if (!hasStoragePermission) {
                  final status = await Permission.storage.request();
                  hasStoragePermission = status.isGranted;
                }
                var dir = await getExternalStorageDirectory();
                if (!Directory("${dir!.path}/RAW").existsSync()) {
                  Directory("${dir!.path}/RAW").createSync(recursive: true);
                }
                try {
                  final taskId = await FlutterDownloader.enqueue(
                    url: 'http://192.168.4.1/download.html?inf=100&sup=200',
                    //url : "https://firebasestorage.googleapis.com/v0/b/storage-3cff8.appspot.com/o/2020-05-29%2007-18-34.mp4?alt=media&token=841fffde-2b83-430c-87c3-2d2fd658fd41",
                    headers: {
                      HttpHeaders.connectionHeader: 'keep-alive',
                      'Content-Disposition': 'attachment; filename=prueba.txt'
                    },
                    fileName: 'prueba.txt',
                    savedDir: dir.path,
                    //timeout: 300000,
                    showNotification: true,
                    //saveInPublicStorage: true,
                    // show download progress in status bar (for Android)
                    openFileFromNotification:
                    false, // click on notification to open downloaded file (for Android)
                  );
                } catch (e) {
                  print("---->Error: $e");
                }
              },
            ),
          ],
        ),
        appBar: AppBar(
          title: const Text('InAppWebView Example'),
        ),
        body: Column(children: <Widget>[
          /*Expanded(
              child: InAppWebView(
            key: GlobalKey(),
            initialUrlRequest: URLRequest(
                url: Uri.parse('http://192.168.4.1/confDownload.html')),
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
          ))*/
        ]),
      ),
    );
  }
}

/*
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(
      debug: true // optional: set false to disable printing logs to console
  );
  FlutterDownloader.registerCallback(DownloadClass.callback);
  runApp(MyApp());
}

class DownloadClass{
  static void callback(String id, DownloadTaskStatus status, int progress){
    print('Download Status: $status');
    print('Download Progress: $progress');
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  int progress = 0;


  final ReceivePort _receivePort = ReceivePort();

  static downloadingCallback(id, status, progress) {
    ///Looking up for a send port
    SendPort? sendPort = IsolateNameServer.lookupPortByName("downloading");

    ///ssending the data
    sendPort!.send([id, status, progress]);
  }


  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    ///register a send port for the other isolates
    IsolateNameServer.registerPortWithName(_receivePort.sendPort, "downloading");


    ///Listening for the data is comming other isolataes
    _receivePort.listen((message) {
      setState(() {
        progress = message[2];
      });

      print(progress);
    });


    FlutterDownloader.registerCallback(downloadingCallback);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[

            Text("$progress", style: TextStyle(fontSize: 40),),

            SizedBox(height: 60,),

            TextButton(
              child: Text("Start Downloading"),

              onPressed: () async {
                final status = await Permission.storage.request();

                if (status.isGranted) {
                  final externalDir = await getExternalStorageDirectory();

                  final id = await FlutterDownloader.enqueue(
                    url:
                    //"https://todologistica.com/utiles/img2018/formato-contenido-2PB.pdf",
                    "http://192.168.4.1/downloadFile.html",
                    savedDir: externalDir!.path,
                    fileName: "download.pdf",
                    showNotification: true,
                    openFileFromNotification: false,
                  );


                } else {
                  print("Permission deined");
                }
              },
            )
          ],
        ),
      ),
    );
  }
}
*/
