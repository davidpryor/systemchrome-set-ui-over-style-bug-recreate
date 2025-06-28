// Recreate the issue with SystemChrome.setSystemUIOverlayStyle being overwritten by internal flutter code
// 3 Scenarios:
// 1. (No AppBar - No Post Frame Callback)
//    SystemChrome.setSystemUIOverlayStyle is called before the Material/Cupertino app is built
// -- This will cause the internal style to be applied because `setSystemUIOverlayStyle` takes
//    the payload of the LAST call to `setSystemUIOverlayStyle` before the platform call is dispatched.
//    fvm/versions/3.32.5/packages/flutter/lib/src/services/system_chrome.dart:712
// 2. (AppBar - No SystemOverlayStyle - No Post Frame Callback)
//    Scaffolding uses an appbar WITHOUT the systemOverlayStyle set AND no post frame callback
// -- This will lead to the call order of 'developers set style' -> "MaterialApp set style" -> "view renderer set style"
//    which causes the initial user set nav bar style to not be changeable (persist the last set nav bar style)
//    fvm/versions/3.32.5/packages/flutter/lib/src/rendering/view.dart:487
// 3. (Postframe Callback)
//    Calling SystemChrome.setSystemUIOverlayStyle after the MaterialApp has been built
// -- This allows the developer set style to be applied after the MaterialApp has set its own style,
//    which is necessary to ensure the developer's style is not overwritten by the MaterialApp's
//    internal style.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Brightness brightness =
      SchedulerBinding.instance.platformDispatcher.platformBrightness;
  bool useBroken = true;
  final MaterialColor lightColor = Colors.red;
  final MaterialColor darkColor = Colors.blue;
  bool useAppBar = false;
  @override
  void dispose() {
    SchedulerBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SystemUiOverlayStyle systemUiOverlayStyle;
    final ThemeData themeData;
    if (brightness == Brightness.dark) {
      systemUiOverlayStyle = SystemUiOverlayStyle(
        systemNavigationBarContrastEnforced: false,
        statusBarBrightness: Brightness.dark,
        statusBarColor: darkColor,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: darkColor,
        systemNavigationBarDividerColor: darkColor,
        systemNavigationBarIconBrightness: Brightness.light,
      );
      themeData = ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: darkColor,
          brightness: Brightness.dark,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            backgroundColor: darkColor,
            foregroundColor: Colors.white,
          ),
        ),
      );
    } else {
      systemUiOverlayStyle = SystemUiOverlayStyle(
        systemNavigationBarContrastEnforced: false,
        statusBarBrightness: Brightness.light,
        statusBarColor: lightColor,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: lightColor,
        systemNavigationBarDividerColor: lightColor,
        systemNavigationBarIconBrightness: Brightness.dark,
      );
      themeData = ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: lightColor,
          brightness: Brightness.light,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            backgroundColor: lightColor,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    /// Using a callback to set the SystemChrome style avoids internal style overwrites
    if (!useBroken) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
      });
    }
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    return MaterialApp(
      title: 'Flutter Demo',
      theme: themeData,
      home: Scaffold(
        appBar: (useAppBar)
            /// Using an AppBar adds a new internal setSystemUIOverlayStyle call in rendering/view.dart
            ? AppBar(
                title: Text("AppBar - No SystemOverlayStyle"),
                backgroundColor: themeData.primaryColor,
              )
            : null,
        body: Center(
          child: Column(
            children: [
              Spacer(flex: 1),
              SizedBox(
                width: 200,
                child: TextButton(
                  onPressed: () => setState(() {
                    brightness = Brightness.dark == brightness
                        ? Brightness.light
                        : Brightness.dark;
                  }),
                  style: themeData.textButtonTheme.style,
                  child: Text("Toggle Brightness/Theme"),
                ),
              ),
              SizedBox(
                width: 200,
                child: TextButton(
                  onPressed: () => setState(() {
                    useBroken = !useBroken;
                  }),
                  style: themeData.textButtonTheme.style,
                  child: Text((useBroken ? "Use Callback" : "Remove Callback")),
                ),
              ),
              SizedBox(
                width: 200,
                child: TextButton(
                  onPressed: () => setState(() {
                    useAppBar = !useAppBar;
                  }),
                  style: themeData.textButtonTheme.style,
                  child: Text((useAppBar ? "Remove AppBar" : "Add AppBar")),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
