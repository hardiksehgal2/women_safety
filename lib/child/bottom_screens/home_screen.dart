import 'dart:math';
import 'dart:io' show Platform;
import 'package:background_sms/background_sms.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shake/shake.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:women_saftey/utils/quotes.dart';
import 'package:women_saftey/widgets/home_widgets/customCarouel.dart';
import 'package:women_saftey/widgets/home_widgets/custom_appBar.dart';
import 'package:women_saftey/widgets/home_widgets/emergency.dart';
import 'package:women_saftey/widgets/home_widgets/safehome/SafeHome.dart';
import 'package:women_saftey/widgets/live_safe.dart';

import '../../db/db_services.dart';
import '../../model/contactsm.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int qIndex = 0;
  Position? _curentPosition;
  String? _curentAddress;
  LocationPermission? permission;

  @override
  void initState() {
    super.initState();
    _getPermission();
    _getCurrentLocation();
    getRandomQuote();



    /////SHAKE FEATURE
    
  }

  Future<void> _getPermission() async {
    // Check if the platform is not web
    if (!kIsWeb) { // Use kIsWeb instead of Platform.isWeb
      // Request the SMS permission only on mobile platforms
      PermissionStatus permissionStatus = await Permission.sms.request();
      if (permissionStatus != PermissionStatus.granted) {
        Fluttertoast.showToast(msg: "SMS permission denied");
      }
    } else {
      // No need to request SMS permission on web
      Fluttertoast.showToast(msg: "Not supported in web");
    }
  }
  _isPermissionGranted() async => await Permission.sms.status.isGranted;

  _sendSms(String phoneNumber, String message, {int? simSlot}) async {
    SmsStatus result = await BackgroundSms.sendMessage(
        phoneNumber: phoneNumber, message: message, simSlot: 1);
    if (result == SmsStatus.sent) {
      print("Sent");
      Fluttertoast.showToast(msg: "send");
    } else {
      Fluttertoast.showToast(msg: "failed");
    }
  }

  _getCurrentLocation() async {
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      Fluttertoast.showToast(msg: "Location messages are denied");
      if (permission == LocationPermission.deniedForever) {
        await Geolocator.requestPermission();
        Fluttertoast.showToast(msg: "Location permission are denied permanently");
      }
    }
    Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        forceAndroidLocationManager: true)
        .then((Position position) {
      setState(() {
        _curentPosition = position;
        print(_curentPosition!.latitude);
        _getAddressFromLatLon();
      });
    }).catchError((e) {
      Fluttertoast.showToast(msg: e.toString());
    });
  }

  _getAddressFromLatLon() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          _curentPosition!.latitude, _curentPosition!.longitude);

      Placemark place = placemarks[0];
      setState(() {
        _curentAddress =
        "${place.locality},${place.postalCode},${place.street},";
      });
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  getRandomQuote() {
    Random random = Random();

    //used in changing state
    setState(() {
      qIndex = random.nextInt(sweetSayings.length);
    });
  }

  getAndSendSms() async {
    List<TContact> contactList = await DatabaseHelper().getContactList();

    String messageBody =
        "https://maps.google.com/?daddr=${_curentPosition!.latitude},${_curentPosition!.longitude}";
    if (await _isPermissionGranted()) {
      contactList.forEach((element) {
        _sendSms("${element.number}", "i am in trouble $messageBody");
      });
    } else {
      Fluttertoast.showToast(msg: "something wrong");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Padding(padding: EdgeInsets.only(top: 6, bottom: 6)),
              CustomAppBar(
                quoteIndex: qIndex,
                onTap: () {
                  getRandomQuote();
                },
              ),
              Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      SizedBox(height: 16),
                      CustomCarouel(),
                      SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: "Emergency".text.bold.xl3.make(),
                      ),
                      SizedBox(height: 16),
                      Emergency(),
                      SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: "Explore LiveSafe".text.bold.xl3.make(),
                      ),
                      SizedBox(height: 16),
                      LiveSafe(),
                      SafeHome(),
                    ],
                  ))
            ],
          ),
        ),
      ),
    );
  }
}