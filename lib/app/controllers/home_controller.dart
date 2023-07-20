// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lan_scanner/lan_scanner.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:http/http.dart' as http;

void message(String message) {
  ScaffoldMessenger.of(Get.context!).clearSnackBars();
  ScaffoldMessenger.of(Get.context!).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: 1.seconds,
    ),
  );
}

class AddressModel {
  Rx<HostModel> host;
  RxDouble progress;
  RxString progressText;
  RxList<File> sentFiles;
  bool isManual;
  int serverPort;

  AddressModel({
    required this.host,
    required this.progress,
    required this.progressText,
    required this.sentFiles,
    this.isManual = false,
    this.serverPort = 3002,
  });
}

class HomeController extends GetxController {
  int DEFAULTPORT = 3002;
  RxString wifiIP = "".obs,
      subnet = "".obs,
      wifiName = "".obs,
      wifiGateway = "".obs;

  RxDouble progress = 0.0.obs;

  RxList<AddressModel> addresses = <AddressModel>[].obs;

  late final Directory appDocumentsDir;
  late RxList<File> appFiles = getAppFiles().obs;
  String get appFilesPath => "${appDocumentsDir.path}/ShareX";

  StreamSubscription? subscription;
  Timer? timeoutTimer;

  bool isScanning = false;

  List<File> getAppFiles() {
    Directory dir = Directory(appFilesPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    var list = dir.listSync().map((e) => File(e.path)).toList();
    list.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return list;
  }

  var networkInfo = NetworkInfo();
  @override
  void onInit() {
    super.onInit();
    getDirAndInit();
  }

  Future<void> getDirAndInit() async {
    appDocumentsDir = Platform.isAndroid
        ? (await getExternalStorageDirectory())!
        : await getApplicationDocumentsDirectory();
    init().then((value) {
      startFileReceiver();
    });
  }

  Future<void> startFileReceiver() async {
    final server = await ServerSocket.bind(wifiIP.value, DEFAULTPORT);
    debugPrint('Serveur d\'écoute démarré');

    server.listen((socket) {
      handleIncomingConnection(socket);
    });
  }

  String shareXHtml = """
  <html>
  <head>
    <meta charset="UTF-8">
    <title>ShareX</title>
    <style>
      *{
        box-sizing: border-box;
      }
    body{
      background-color: #16161D;
      color: #fff;
      font-family: sans-serif;
      font-size: 16px;
      line-height: 1.5;
      margin: 0;
      padding: 0;
    }
    .container{
      width: 100%;
      height: 100vh;
      max-width: 600px;
      margin: 0 auto;
      padding: 0 20px;
      justify-content: center;
      align-items: center;
      display: flex;
    }
    h1{
      font-size: 3.5rem;
      font-weight: 700;
      margin: 0;
      padding: 0;
    }
    .blue{
      color: #00A8FF;
      font-weight: 900;
      font-size: 4rem;
      font-style: italic;
    }
    </style>
  
  </head>
    <body>
      <div class="container"> <h1>Share<span class="blue">X</span> </h1> </div>
    </body>
  </html>

""";

  Future<void> handleIncomingConnection(Socket socket) async {
    String receivedData = '';
    int? expectedSize;
    socket.listen((List<int> data) async {
      receivedData += String.fromCharCodes(data);
      if (receivedData.startsWith("GET / HTTP")) {
        socket.write(
            "HTTP/1.1 200 OK\nContent-Type: text/html; charset=UTF-8\n\n$shareXHtml");
        socket.close();
        return;
      }
      if (receivedData.startsWith("~notify~")) {
        var ip = receivedData.split("~notify~")[1].split("~~")[0];
        var port = receivedData.split("~notify~")[1].split("~~")[1];
        Get.dialog(
          AlertDialog(
            title: const Text("Notification"),
            content: Text("$ip vous a notifié sa présence."),
            actions: [
              TextButton(
                onPressed: () {
                  addHost(ip, port, fromNotification: true);
                  Get.back();
                },
                child: const Text("Ajouter"),
              ),
              TextButton(
                onPressed: () {
                  Get.back();
                },
                child: const Text("Refuser"),
              ),
            ],
          ),
        );
        return;
      }

      // Vérifier si la chaîne JSON est complète (terminée par une nouvelle ligne)
      if (expectedSize == null) {
        final newlineIndex = receivedData.indexOf('\n');
        if (newlineIndex != -1) {
          // Extraire et enlever la taille de message de la chaîne reçue
          final sizeStr = receivedData.substring(0, newlineIndex);
          receivedData = receivedData.substring(newlineIndex + 1);
          expectedSize = int.parse(sizeStr);
        }
      }
      if (expectedSize != null && receivedData.length >= expectedSize!) {
        // Extraire l'objet JSON
        final jsonData = jsonDecode(receivedData.substring(0, expectedSize));
        // Récupérer le nom du fichier et les données binaires
        final String fileName = jsonData["filename"];
        final String base64Data = jsonData["data"];

        // Convertir les données binaires encodées en base64 en liste d'entiers
        final List<int> fileBytes = base64Decode(base64Data);

        // Sauvegarder les données reçues dans un fichier
        String fn = '$appFilesPath${Platform.pathSeparator}$fileName';
        final File receivedFile = await File(fn).create(recursive: true);
        receivedFile.writeAsBytesSync(fileBytes, flush: true);
        // await OpenFile.open(fn);
        // print(receivedData);
        appFiles.value = getAppFiles();

        // Réinitialiser les variables pour la prochaine réception
        receivedData = receivedData.substring(expectedSize!);
        expectedSize = null;
      }
    }, onDone: () {
      socket.close();
    });
  }

  void sendFiles(int index) async {
    // Code pour envoyer les fichiers en utilisant la barre de progression
    var selectedFiles = await pickFiles();
    final totalFiles = selectedFiles.length;
    var address = addresses[index];
    address.progressText.value = "Envoi de $totalFiles fichiers";
    address.progress.value = 0.0;
    double currentProgress = 0.0;
    if (address.host.value.ip == wifiIP.value) {
      message("Vous envoyez des fichiers à vous-même");
    }
    if (!address.host.value.isReachable) {
      message("L'adresse ${address.host.value.ip} n'est pas joignable");
      return;
    }

    bool hasError = false;

    for (final file in selectedFiles) {
      try {
        final Socket socket =
            await Socket.connect(address.host.value.ip, address.serverPort);
        // Envoyer le fichier ici et mettre à jour la progression
        File f = File(file);
        await sendFile(f, socket);
        address.sentFiles.add(f);
      } catch (_) {
        message(
            "Erreur lors de l'envoi du fichier ${file.split(Platform.pathSeparator).last}");

        hasError = true;
      }
      // socket.close();

      currentProgress += 1.0;
      final progressPercentage = currentProgress / totalFiles;
      address.progress.value = progressPercentage;
    }

    address.progressText.value =
        hasError ? "Erreur lors de l'envoi" : "Envoi terminé";
  }

  Future<List<String>> pickFiles() async {
    final FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result != null) {
      return result.paths.map((path) => path!).toList();
    } else {
      // Aucun fichier sélectionné
      return [];
    }
  }

  Future<void> sendFile(File file, Socket socket) async {
    try {
      // Lire les données du fichier
      List<int> fileBytes = await file.readAsBytes();
      String base64Data = base64Encode(fileBytes);

      // Créer l'objet JSON avec le nom du fichier et les données binaires
      final Map<String, dynamic> jsonData = {
        "filename": file.path
            .split(Platform.pathSeparator)
            .last, // Récupérer le nom du fichier avec son extension
        "data": base64Data,
      };

      // Convertir l'objet JSON en chaîne et l'envoyer au travers du socket
      final jsonString = jsonEncode(jsonData);

      // Envoyer la taille du message JSON au début de la communication
      final messageSize = utf8.encode('${jsonString.length}\n');
      socket.add(messageSize);

      // Attendre que le récepteur confirme la réception de la taille du message
      await socket.flush();

      // Envoyer le message JSON contenant le nom du fichier et les données binaires
      final jsonDataBytes = utf8.encode(jsonString);
      socket.add(jsonDataBytes);

      // socket.write(jsonString);
      // await socket.addStream(file.openRead());
    } catch (e) {
      //
    }
  }

  Future<void> init() async {
    await fetch();
    scan();
  }

  void scan() {
    if (subnet.value == "") {
      message("Aucune adresse à scanner");
      return;
    }
    if (isScanning) {
      message("Scan en cours");
      return;
    }
    subscription?.cancel();
    addresses.value = addresses.where((element) => element.isManual).toList();
    isScanning = true;

    final scanner = LanScanner();

    try {
      final stream = scanner.icmpScan(
        subnet.value,
        progressCallback: (p) {
          progress.value = p;
          timeoutTimer?.cancel();
          timeoutTimer = Timer(3000.milliseconds, () {
            if (progress.value < .99) {
              message("Erreur lors du scan. Réessayez.");
            }
            progress.value = 0;
            isScanning = false;
          });
          if (p == .99) {
            progress.value = 1.0;
            isScanning = false;
          }
        },
      );

      subscription = stream.listen((HostModel device) {
        var address = AddressModel(
          host: device.obs,
          progress: 0.0.obs,
          progressText: "Aucun envoi en cours".obs,
          sentFiles: <File>[].obs,
        );
        addresses.add(address);
        addresses.sort((a, b) => !a.host.value.isReachable ? 1 : -1);
      });
    } catch (e) {
      debugPrint("oups");
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> fetch() async {
    try {
      wifiIP.value = await networkInfo.getWifiIP() ?? "Aucun IP";
      subnet.value = ipToCSubnet(wifiIP.value);
    } catch (e) {
      //
    }
    try {
      wifiName.value = await networkInfo.getWifiName() ??
          "Appareil non connecté à un réseau wifi";
      if (wifiName.value.trim().isEmpty) {
        wifiName.value = "Aucun nom de wifi trouvé";
      }
    } catch (e) {
      //
    }

    try {
      wifiGateway.value =
          await networkInfo.getWifiGatewayIP() ?? "Aucune passerelle";
    } catch (e) {
      //
    }
  }

  Future<void> addHost(String ip, String port,
      {bool fromNotification = false}) async {
    if (addresses.where((element) => element.host.value.ip == ip).isNotEmpty) {
      message("Cette adresse est déjà dans la liste");
      return;
    }

    HostModel device = HostModel(ip: ip, isReachable: false);

    var address = AddressModel(
      host: device.obs,
      progress: 0.0.obs,
      progressText: "Aucun envoi en cours".obs,
      sentFiles: <File>[].obs,
      isManual: true,
    );
    addresses.add(address);
    checkIpAddressAvailability(ip, int.parse(port), fromNotification)
        .then((value) {
      if (value) {
        if (ip != wifiIP.value) {
          Socket.connect(ip, int.parse(port),
                  timeout: const Duration(seconds: 5))
              .then((socket) => socket.write("~notify~$wifiIP~~$DEFAULTPORT"));
        }
      }
      address.host.value = HostModel(ip: ip, isReachable: value);
    });

    addresses.sort((a, b) => !a.host.value.isReachable ? 1 : -1);

    // Socket.connect(ip, int.parse(port), timeout: const Duration(seconds: 5))
    //     .then((socket) {
    //   socket.write("~notify~$wifiIP~~$DEFAULTPORT");
    //   address.host.value = HostModel(ip: ip, isReachable: true);
    //   socket.destroy();
    // }).catchError((error) {});
    // addresses.sort((a, b) => !a.host.value.isReachable ? 1 : -1);
  }

  Future<bool> checkIpAddressAvailability(
      String ipAddress, int port, bool fromNotification) async {
    if (fromNotification) {
      return true;
    }
    try {
      // 192.168.122.247
      String url = "http://$ipAddress:$port";
      http.Response response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(milliseconds: 500));

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } on SocketException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  void removeHost(int index) {
    addresses.removeAt(index);
  }

  void notify(int index) {
    Socket.connect(addresses[index].host.value.ip, addresses[index].serverPort,
            timeout: const Duration(seconds: 5))
        .then((socket) {
      // send my ip
      socket.write("~notify~$wifiIP~~$DEFAULTPORT");

      socket.destroy();
    }).catchError((error) {});
  }
}
