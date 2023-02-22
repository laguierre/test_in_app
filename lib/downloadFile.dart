import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:flutter_js/javascript_runtime.dart';
import 'package:path_provider/path_provider.dart';

class DownloadFile extends StatefulWidget {
  @override
  _DownloadFileState createState() => _DownloadFileState();
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

class _DownloadFileState extends State<DownloadFile> {
  InAppWebViewController? webView;
  final ReceivePort _port = ReceivePort();
  final JavascriptRuntime jsRuntime = getJavascriptRuntime();
  InAppWebViewController? _webViewPopupController;

  void showAlertDialog(String file) async {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Archivo descargado'),
            content: const Text(''),
            actions: [

          ElevatedButton(
          style:
          ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () async {
            if(await File(file).exists()){
            Share.shareXFiles([XFile(file)], text: 'Archivo descargado');
            }
          },
          child: const Text('Compartir')),




              ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Ok')),
            ],
          );
        });
  }

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
                child: const Icon(Icons.downloading_sharp),
                onPressed: () async {
                  CheckPermision();
                  final Dio _dio = Dio();
                  var dir = await getApplicationDocumentsDirectory();
                  String? downloadsDirectoryPath =
                      (await DownloadsPath.downloadsDirectory())?.path;
                  print(downloadsDirectoryPath);

                  print(dir.absolute);
                  final response = await _dio.download(
                    //'http://192.168.4.1/download.html?inf=0&sup=0',
                    'http://192.168.4.1/downloadFile.html',
                    //'${dir.path}/raw/test.raw',
                    '$downloadsDirectoryPath/11.raw',
                    onReceiveProgress: (received, total) async {
                      if (total != -1) {
                        print(
                            (received / total * 100).toStringAsFixed(0) + "%");
                        showAlertDialog('$downloadsDirectoryPath/11.raw');

                      }
                    },
                  );
                }),
            const SizedBox(width: 30),
            FloatingActionButton(
              foregroundColor: Colors.red,
              child: const Icon(
                Icons.sim_card_download,
              ),
              onPressed: () async {
                await CheckPermision();
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
                print('URL: $url');

                /*final anchor =
                    html.document.createElement('a') as html.AnchorElement
                      ..href =
                          a
                      ..style.display = "none"
                      ..download = 'file.txt'
                      ..target = '_blank';


                print(anchor.toString());*/
                final div = html.DivElement();
                var link = html.document.createElement("a")
                  ..setAttribute('href', "google.com.ar")
                  ..classes.add("greeting")
                  ..setAttribute('download', 'pepe.txt')
                  ..setAttribute('target', '_blank')
                  ..appendText("");
                div.append(link);
                link.click();
                div.remove();

                html.window.open("google.com.ar", "_blank");
                // Print outer HTML
                print(div.outerHtml);
                // --> <div><h1>Hello world</h1></div>

                // Do a CSS query
                //print(div.querySelector("div > .greeting")!.text);
                // --> Hello world

                /*print(anchor.innerText);
                html.document.body!.innerHtml = anchor.innerText;*/
                print('----->Edu said ${html.document.body}');

                /*anchor.click();
                print('--->Click');
                html.document.body?.children.remove(anchor);
                html.Url.revokeObjectUrl(
                    'http://192.168.4.1/download.html?inf=100&sup=200');*/

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
            _OpenWithSystemBrowser(),
            const SizedBox(width: 30),
            _FlutterDownloader(),
          ],
        ),
        appBar: AppBar(
          title: const Text('InAppWebView Example'),
        ),
        body: Column(children: <Widget>[
          Expanded(
              child: InAppWebView(
            initialData: InAppWebViewInitialData(data: """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>Flutter InAppWebView</title>
</head>
<body>
  <a style="margin: 50px; background: #333; color: #fff; font-weight: bold; font-size: 20px; padding: 15px; display: block;"
    href="https://github.com/flutter"
    target="_blank">
    Click here to open https://github.com/flutter in a popup!
  </a>
</body>
</html>
"""),
            key: GlobalKey(),
            initialUrlRequest: URLRequest(
                url: Uri.parse('http://192.168.4.1/confDownload.html')),
            // initialHeaders: {},
            initialOptions: InAppWebViewGroupOptions(
              android: AndroidInAppWebViewOptions(
                /*safeBrowsingEnabled: false,
                useHybridComposition: true,
                geolocationEnabled: true,
                 cacheMode: AndroidCacheMode.LOAD_DEFAULT,
                disableDefaultErrorPage: false,*/
                // useHybridComposition: true,
                supportMultipleWindows: true,
              ),
              crossPlatform: InAppWebViewOptions(
                //clearCache: true,
                //javaScriptEnabled: true,
                javaScriptCanOpenWindowsAutomatically: true,
                /*useOnDownloadStart: true,
                useShouldOverrideUrlLoading: true,
                mediaPlaybackRequiresUserGesture: false,
                horizontalScrollBarEnabled: false,
                allowFileAccessFromFileURLs: true,*/
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
            onCreateWindow: (controller, createWindowRequest) async {
              print("onCreateWindow");

              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    content: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: 400,
                      child: InAppWebView(
                        // Setting the windowId property is important here!
                        windowId: createWindowRequest.windowId,
                        initialOptions: InAppWebViewGroupOptions(
                          crossPlatform: InAppWebViewOptions(
                              //debuggingEnabled: true,
                              ),
                        ),
                        onWebViewCreated: (InAppWebViewController controller) {
                          _webViewPopupController = controller;
                        },
                        onLoadStart:
                            (InAppWebViewController controller, Uri? url) {
                          print("onLoadStart popup $url");
                        },
                        onLoadStop:
                            (InAppWebViewController controller, Uri? url) {
                          print("onLoadStop popup $url");
                        },
                      ),
                    ),
                  );
                },
              );

              return true;
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

  Future<void> CheckPermision() async {
    var hasStoragePermission = await Permission.storage.isGranted;
    if (!hasStoragePermission) {
      final status = await Permission.storage.request();
      hasStoragePermission = status.isGranted;
    }
    var dir = await getExternalStorageDirectory();
    if (!Directory("${dir!.path}/RAW").existsSync()) {
      Directory("${dir.path}/RAW").createSync(recursive: true);
    }
  }
}

class _OpenWithSystemBrowser extends StatelessWidget {
  const _OpenWithSystemBrowser({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      child: const Icon(Icons.refresh),
      onPressed: () {
        InAppBrowser.openWithSystemBrowser(
            url: Uri.parse(
                'http://192.168.4.1/confDownload.html')); //Uri.parse('http://192.168.4.1/downloadFile.html'));http://192.168.4.1/download.html?inf=' + limInf +'&sup=' limSup)
      },
    );
  }
}

class _FlutterDownloader extends StatelessWidget {
  const _FlutterDownloader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      child: const Icon(Icons.download),
      onPressed: () async {
        var hasStoragePermission = await Permission.storage.isGranted;
        if (!hasStoragePermission) {
          final status = await Permission.storage.request();
          hasStoragePermission = status.isGranted;
        }
        var dir = await getExternalStorageDirectory();
        if (!Directory("${dir!.path}/RAW").existsSync()) {
          Directory("${dir.path}/RAW").createSync(recursive: true);
        }
        try {
          final taskId = await FlutterDownloader.enqueue(
            url: 'http://192.168.4.1/download.html?inf=100&sup=200',
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
    );
  }
}
