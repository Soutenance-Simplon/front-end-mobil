// Flutter web plugin registrant file.
//
// Generated file. Do not edit.
//

// @dart = 2.13
// ignore_for_file: type=lint

import 'package:connectivity_plus/src/connectivity_plus_web.dart';
import 'package:device_info_plus/src/device_info_plus_web.dart';
import 'package:file_picker/_internal/file_picker_web.dart';
import 'package:firebase_auth_web/firebase_auth_web.dart';
import 'package:firebase_core_web/firebase_core_web.dart';
import 'package:flutter_facebook_auth_web/flutter_facebook_auth_web.dart';
import 'package:flutter_secure_storage_web/flutter_secure_storage_web.dart';
import 'package:geolocator_web/geolocator_web.dart';
import 'package:image_picker_for_web/image_picker_for_web.dart';
import 'package:livekit_client/livekit_client_web.dart';
import 'package:mobile_scanner/src/web/mobile_scanner_web.dart';
import 'package:package_info_plus/src/package_info_plus_web.dart';
import 'package:url_launcher_web/url_launcher_web.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void registerPlugins([final Registrar? pluginRegistrar]) {
  final Registrar registrar = pluginRegistrar ?? webPluginRegistrar;
  ConnectivityPlusWebPlugin.registerWith(registrar);
  DeviceInfoPlusWebPlugin.registerWith(registrar);
  FilePickerWeb.registerWith(registrar);
  FirebaseAuthWeb.registerWith(registrar);
  FirebaseCoreWeb.registerWith(registrar);
  FlutterFacebookAuthPlugin.registerWith(registrar);
  FlutterSecureStorageWeb.registerWith(registrar);
  GeolocatorPlugin.registerWith(registrar);
  ImagePickerPlugin.registerWith(registrar);
  LiveKitWebPlugin.registerWith(registrar);
  MobileScannerWeb.registerWith(registrar);
  PackageInfoPlusWebPlugin.registerWith(registrar);
  UrlLauncherPlugin.registerWith(registrar);
  registrar.registerMessageHandler();
}
