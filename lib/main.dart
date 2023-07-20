import 'dart:io';

import 'package:sharex/app/bindings/home_binding.dart';
import 'package:sharex/app/bindings/login_binding.dart';
import 'package:sharex/app/bindings/settings_binding.dart';
import 'package:sharex/app/bindings/signup_binding.dart';
import 'package:sharex/app/bindings/welcome_binding.dart';
import 'package:sharex/app/routes/route.dart';
import 'package:sharex/app/ui/pages/home_page/home_page.dart';
import 'package:sharex/app/ui/pages/login_page/login_page.dart';
import 'package:sharex/app/ui/pages/settings_page/settings_page.dart';
import 'package:sharex/app/ui/pages/signup_page/signup_page.dart';
import 'package:sharex/app/ui/pages/welcome_page/welcome_page.dart';
import 'package:sharex/app/ui/theme/data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:window_size/window_size.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowTitle('ShareX');
    setWindowMaxSize(const Size(400, 800));
    setWindowMinSize(const Size(400, 800));
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'ShareX',
      debugShowCheckedModeBanner: false,
      theme: lightThemeData,
      darkTheme: darkThemeData,
      themeMode: ThemeMode.system,
      initialRoute: Routes.home,
      getPages: [
        GetPage(
          name: Routes.home,
          page: () => const HomePage(),
          binding: HomeBinding(),
        ),
        GetPage(
          name: Routes.welcome,
          page: () => const WelcomePage(),
          binding: WelcomeBinding(),
        ),
        GetPage(
          name: Routes.settings,
          page: () => const SettingsPage(),
          binding: SettingsBinding(),
        ),
        GetPage(
          name: Routes.login,
          page: () => const LoginPage(),
          binding: LoginBinding(),
        ),
        GetPage(
          name: Routes.signup,
          page: () => const SignupPage(),
          binding: SignupBinding(),
        ),
      ],
    );
  }
}
