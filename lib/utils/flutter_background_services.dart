import 'dart:ui';
import 'dart:async';

import 'package:background_location/background_location.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Import for platform check
import 'package:background_location/background_location.dart' as bg_location;
import 'package:background_sms/background_sms.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shake/shake.dart';
import 'package:telephony/telephony.dart';
import 'package:vibration/vibration.dart';

import '../db/db_services.dart';
import '../model/contactsm.dart';

sendMessage(String messageBody) async {
  List<TContact> contactList = await DatabaseHelper().getContactList();
  if (contactList.isEmpty) {
    Fluttertoast.showToast(msg: "no number exist please add a number");
  } else {
    for (var i = 0; i < contactList.length; i++) {
      Telephony.backgroundInstance
          .sendSms(to: contactList[i].number, message: messageBody)
          .then((value) {
        Fluttertoast.showToast(msg: "message send");
      });
    }
  }
}

Future<void> initializeService() async {
  if (!kIsWeb) { // Check if not running on web
    final service = FlutterBackgroundService();
    AndroidNotificationChannel channel = AndroidNotificationChannel("Script Academy", "Foreground Services", importance: Importance.high);
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      iosConfiguration: IosConfiguration(),
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: true,
        autoStart: true,
        notificationChannelId: "script academy",
        initialNotificationTitle: "foreground service",
        initialNotificationContent: "initializing",
        foregroundServiceNotificationId: 888,
      ),
    );
    service.startService();
  } else {
    print("FlutterBackgroundService is not supported on web platform.");
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  bg_location.Location? clocation;

  DartPluginRegistrant.ensureInitialized();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  if (!kIsWeb && service is AndroidServiceInstance) { // Check if not running on web and Android
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }
  service.on('stopService').listen((event) {
    service.stopSelf();
  });
  await BackgroundLocation.setAndroidNotification(
    title: "Location tracking is running in the background!",
    message: "You can turn it off from settings menu inside the app",
    icon: '@mipmap/ic_logo',
  );
  BackgroundLocation.startLocationService(
    distanceFilter: 20,
  );

  BackgroundLocation.getLocationUpdates((location) {
    clocation = location;
  });
  if (!kIsWeb && service is AndroidServiceInstance) { // Check if not running on web and Android
    if (await service.isForegroundService()) {
      //   await Geolocator.getCurrentPosition(
      //     desiredAccuracy: LocationAccuracy.best,
      //     forceAndroidLocationManager: true)
      //     .then((Position position) {
      //     print("Background Location ${position.latitude}");
      // }).catchError((e) {
      //   Fluttertoast.showToast(msg: e.toString());
      // });
      ShakeDetector.autoStart(
        shakeThresholdGravity: 7,
        shakeSlopTimeMS: 500,
        shakeCountResetTime: 3000,
        minimumShakeCount: 1,
        onPhoneShake: () async {
          if (await Vibration.hasVibrator() ?? false) {
            print("Test 2");
            if (await Vibration.hasCustomVibrationsSupport() ?? false) {
              print("Test 3");
              Vibration.vibrate(duration: 1000);
            } else {
              print("Test 4");
              Vibration.vibrate();
              await Future.delayed(Duration(milliseconds: 500));
              Vibration.vibrate();
            }
            print("Test 5");
          }
          String messageBody =
              "https://www.google.com/maps/search/?api=1&query=${clocation!.latitude}%2C${clocation!.longitude}";
          sendMessage(messageBody);
        },
      );

      flutterLocalNotificationsPlugin.show(
        888,
        "women safety app",
        clocation == null
            ? "please enable location to use app"
            : "shake feature enable ${clocation!.latitude}",
        NotificationDetails(
          android: AndroidNotificationDetails(
            "script academy",
            "foreground service",
            icon: 'ic_bg_service_small',
            ongoing: true,
          ),
        ),
      );
    }
  }
}
