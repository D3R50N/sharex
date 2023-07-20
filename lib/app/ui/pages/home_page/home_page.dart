import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:lan_scanner/lan_scanner.dart';
import 'package:open_file/open_file.dart';
import 'package:sharex/app/ui/theme/colors.dart';
import 'package:sharex/app/ui/utils/functions.dart';
import 'package:sharex/extensions/file_extension.dart';
import 'package:sharex/extensions/int_extension.dart';
import '../../../controllers/home_controller.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: appBrand(context),
        actions: [
          GestureDetector(
            onTap: () {
              Get.changeThemeMode(
                Get.isDarkMode ? ThemeMode.light : ThemeMode.dark,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Icon(
                Icons.light_mode,
                color: Get.isDarkMode ? Colors.amber : rgb(52, 3, 67),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: PageView(
          physics: const BouncingScrollPhysics(),
          onPageChanged: (p) {
            controller.appFiles.value = controller.getAppFiles();
          },
          children: [
            mainPageView(context),
            // receive files page view
            Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Fichiers reçus",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(20),
                    Expanded(
                      child: Obx(
                        () => ShaderMask(
                          shaderCallback: (rect) {
                            return const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white,
                                Colors.white,
                                Colors.white,
                                Colors.white,
                                Colors.white,
                                Colors.white,
                                Colors.white,
                                Colors.transparent,
                              ],
                            ).createShader(
                              Rect.fromLTRB(
                                0,
                                0,
                                rect.width,
                                rect.height,
                              ),
                            );
                          },
                          child: ListView(
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              for (var file in controller.appFiles)
                                ListTile(
                                  isThreeLine: true,
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        file
                                            .lastAccessedSync()
                                            .toString()
                                            .split(".")[0]
                                            .split(":")
                                            .sublist(0, 2)
                                            .join("h")
                                            .split(" ")
                                            .join(" à "),
                                        style: const TextStyle(),
                                      ),
                                      Text(
                                        file.statSync().size.toFileSize,
                                      ),
                                    ],
                                  ),
                                  leading: file.isImage
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          child: Image.file(
                                            file,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : file.isVideo
                                          ? Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                              child: const Icon(
                                                Icons.play_arrow_rounded,
                                                color: Colors.white,
                                              ),
                                            )
                                          : file.isAudio
                                              ? Container(
                                                  width: 50,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    color: Colors.black54,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5),
                                                  ),
                                                  child: const Icon(
                                                    Icons.audiotrack_rounded,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : Container(
                                                  width: 50,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    color: Colors.black54,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5),
                                                  ),
                                                  child: const Icon(
                                                    Icons
                                                        .insert_drive_file_rounded,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                  minLeadingWidth: 0,
                                  onTap: () async {
                                    await OpenFile.open(file.path);
                                  },
                                  title: Text(
                                    file.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              const Gap(100),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  Padding mainPageView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(
            () => GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: controller.wifiIP.value))
                    .then((_) {
                  message("Adresse IP copiée");
                });
              },
              child: Text(
                controller.wifiIP.value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 40,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const Gap(10),
          Obx(() => Text(
                controller.wifiName.value,
                textAlign: TextAlign.center,
              )),
          const Gap(10),
          Obx(() => Text(
                controller.wifiGateway.value,
                textAlign: TextAlign.center,
              )),
          const Gap(50),
          // progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Obx(
                () => Transform.scale(
                  scale: 3,
                  child: Stack(
                    children: [
                      CircularProgressIndicator(
                        value: controller.progress.value,
                        color: Theme.of(context).primaryColor,
                        strokeWidth: 1,
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 12,
                        child: Text(
                          "${(controller.progress.value * 100).toStringAsFixed(0)}%",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                            color: Theme.of(context).primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Gap(50),
          // scan button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: GetPlatform.isWindows
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      scanBtn(context),
                    ],
                  )
                : scanBtn(context),
          ),
          const Gap(20),
          // list of address.hosts
          Row(
            children: [
              Obx(() => Text(
                    "Liste des appareils connectés ( ${controller.addresses.length} )",
                    style: const TextStyle(),
                  )),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  // add manually adress
                  TextEditingController ipController = TextEditingController();
                  TextEditingController portController =
                      TextEditingController();
                  Get.dialog(
                    AlertDialog(
                      title: const Text(
                        "Ajouter manuellement une adresse",
                        textAlign: TextAlign.center,
                      ),
                      content: SizedBox(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: ipController,
                              decoration: const InputDecoration(
                                hintText: "Adresse IP",
                              ),
                            ),
                            const Gap(20),
                            TextField(
                              controller: portController,
                              decoration: InputDecoration(
                                hintText:
                                    "Port du serveur (${controller.DEFAULTPORT} par défaut)",
                              ),
                            ),
                            const Gap(20),
                            ElevatedButton(
                              onPressed: () {
                                if (!ipController.text.isIPv4 &&
                                    !ipController.text.isIPv6) {
                                  message("Adresse IP invalide");
                                  return;
                                }
                                if (portController.text.isEmpty) {
                                  portController.text =
                                      controller.DEFAULTPORT.toString();
                                } else if (!portController.text.isNumericOnly) {
                                  message("Port invalide");
                                  return;
                                }
                                controller.addHost(
                                    ipController.text, portController.text);
                                Get.back();
                              },
                              child: const Text(
                                "Ajouter",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.add),
                ),
              ),
            ],
          ),
          const Gap(10),

          Expanded(
            child: Obx(
              () => ListView.builder(
                itemCount: controller.addresses.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final address = controller.addresses[index];
                  return Obx(
                    () => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: ListTile(
                        onTap: () async {
                          address.host.value = HostModel(
                            ip: address.host.value.ip,
                            isReachable:
                                await controller.checkIpAddressAvailability(
                                    address.host.value.ip,
                                    address.serverPort,
                                    false),
                          );

                          // controller.sendFiles(index);
                          if (!address.host.value.isReachable) {
                            message("Appareil hors ligne");
                            return;
                          }
                          Get.dialog(
                            AlertDialog(
                              title: Text(
                                "Envoyer des fichiers à ${address.host.value.ip}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              content: SizedBox(
                                height: 300,
                                width: 300,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Expanded(
                                      child: Obx(
                                        () => controller.addresses[index]
                                                .sentFiles.isEmpty
                                            ? Center(
                                                child: Text(
                                                  "Aucun fichier envoyé",
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .textTheme
                                                        .bodyLarge!
                                                        .color!
                                                        .withOpacity(.5),
                                                  ),
                                                ),
                                              )
                                            : ListView(
                                                shrinkWrap: true,
                                                physics:
                                                    const BouncingScrollPhysics(),
                                                children: [
                                                  for (var file in controller
                                                      .addresses[index]
                                                      .sentFiles)
                                                    Padding(
                                                      padding: const EdgeInsets
                                                              .symmetric(
                                                          vertical: 10),
                                                      child: ListTile(
                                                        leading: file.isImage
                                                            ? ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            5),
                                                                child:
                                                                    Image.file(
                                                                  file,
                                                                  width: 50,
                                                                  height: 50,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                ),
                                                              )
                                                            : file.isVideo
                                                                ? Container(
                                                                    width: 50,
                                                                    height: 50,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: Colors
                                                                          .black54,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              5),
                                                                    ),
                                                                    child:
                                                                        const Icon(
                                                                      Icons
                                                                          .play_arrow_rounded,
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                  )
                                                                : file.isAudio
                                                                    ? Container(
                                                                        width:
                                                                            50,
                                                                        height:
                                                                            50,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          color:
                                                                              Colors.black54,
                                                                          borderRadius:
                                                                              BorderRadius.circular(5),
                                                                        ),
                                                                        child:
                                                                            const Icon(
                                                                          Icons
                                                                              .audiotrack_rounded,
                                                                          color:
                                                                              Colors.white,
                                                                        ),
                                                                      )
                                                                    : Container(
                                                                        width:
                                                                            50,
                                                                        height:
                                                                            50,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          color:
                                                                              Colors.black54,
                                                                          borderRadius:
                                                                              BorderRadius.circular(5),
                                                                        ),
                                                                        child:
                                                                            const Icon(
                                                                          Icons
                                                                              .insert_drive_file_rounded,
                                                                          color:
                                                                              Colors.white,
                                                                        ),
                                                                      ),
                                                        minLeadingWidth: 0,
                                                        onTap: () async {
                                                          await OpenFile.open(
                                                              file.path);
                                                        },
                                                        title: Text(
                                                          file.name,
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(5),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                      ),
                                    ),
                                    const Gap(20),
                                    ElevatedButton(
                                      onPressed: () async {
                                        controller.sendFiles(index);
                                        Get.back();
                                      },
                                      child: const Text(
                                        "Sélectionner des fichiers",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        onLongPress: () {
                          Get.dialog(
                            AlertDialog(
                              title: GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(
                                          text: address.host.value.ip))
                                      .then((_) {
                                    message("Adresse IP copiée");
                                  });
                                },
                                child: Text(
                                  address.host.value.ip ==
                                          controller.wifiIP.value
                                      ? "Vous êtes connecté à ${address.host.value.ip}"
                                      : "Que voulez-vous faire avec ${address.host.value.ip}?",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              content: SizedBox(
                                child: address.host.value.ip ==
                                        controller.wifiIP.value
                                    ? Text(
                                        "Aucune action possible",
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyLarge!
                                              .color!
                                              .withOpacity(.5),
                                        ),
                                        textAlign: TextAlign.center,
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () async {
                                              controller.notify(index);
                                              Get.back();
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(context)
                                                  .bottomNavigationBarTheme
                                                  .backgroundColor,
                                            ),
                                            child: const Text(
                                              "Notifier",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              controller.removeHost(index);
                                              Get.back();
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: errorColor,
                                            ),
                                            child: const Text(
                                              "Supprimer",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          );
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        title: Row(
                          children: [
                            Text(address.host.value.ip +
                                (address.host.value.ip ==
                                        controller.wifiIP.value
                                    ? " (vous)"
                                    : "")),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: address.host.value.isReachable
                                    ? successColor.withOpacity(.2)
                                    : errorColor.withOpacity(.2),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                address.host.value.isReachable
                                    ? "en ligne"
                                    : "hors ligne",
                                style: TextStyle(
                                  color: address.host.value.isReachable
                                      ? successColor
                                      : errorColor,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Obx(() => Text(controller
                                .addresses[index].progressText.value)),
                            const Gap(10),
                            Obx(
                              () => ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: LinearProgressIndicator(
                                  value: controller
                                      .addresses[index].progress.value,
                                  backgroundColor: Colors.black26,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Obx scanBtn(BuildContext context) {
    return Obx(
      () => TextButton(
        onPressed:
            controller.progress.value == 0.0 || controller.progress.value == 1.0
                ? controller.init
                : null,
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).primaryColor,
          backgroundColor:
              Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          padding: const EdgeInsets.symmetric(
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          elevation: 1,
        ),
        child: Container(
          padding: GetPlatform.isWindows
              ? const EdgeInsets.symmetric(horizontal: 30, vertical: 10)
              : null,
          child: Text(
            controller.progress.value == 0.0 || controller.progress.value == 1.0
                ? "Scanner"
                : "Scan en cours..",
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}
