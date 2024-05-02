import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:velocity_x/velocity_x.dart';
import 'dart:io';

class MessageTextField extends StatefulWidget {
  final String currentId;
  final String friendId;

  MessageTextField({Key? key, required this.currentId, required this.friendId}) : super(key: key);

  @override
  State<MessageTextField> createState() => _MessageTextFieldState();
}

class _MessageTextFieldState extends State<MessageTextField> {
  final TextEditingController _controller = TextEditingController();

  Position? _currentPosition;
  String? _currentAddress;
  String? message;
  File? imageFile;

  LocationPermission? permission;
  Future getImage()async{
      ImagePicker _picker=ImagePicker();
      await _picker.pickImage(source: ImageSource.gallery).then((XFile? xFile)  {
        if(xFile!=null){
          imageFile=File(xFile.path);
          uploadImage();
        }
      });
  }
  Future<void> uploadImage() async {
    if (imageFile == null) {
      Fluttertoast.showToast(msg: 'No image selected');
      return;
    }

    String fileName = Uuid().v1();
    try {
      Reference ref = FirebaseStorage.instance.ref().child('images').child("$fileName.jpg");
      TaskSnapshot uploadTask = await
      ref.putFile(imageFile!);
      String imageUrl = await uploadTask.ref.getDownloadURL();

      await sendMessage(imageUrl, 'img');
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }
  Future<void> getImageFromCamera() async {
    ImagePicker _picker = ImagePicker();
    try {
      final XFile? xFile = await _picker.pickImage(source: ImageSource.camera);
      if (xFile != null) {
        setState(() {
          imageFile = File(xFile.path);
        });
        uploadImage();
      }
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }
  Future _getCurrentLocation() async {
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      Fluttertoast.showToast(msg: "Location permissions are  denind");
      if (permission == LocationPermission.deniedForever) {
        Fluttertoast.showToast(
            msg: "Location permissions are permanently denind");
      }
    }
    Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        forceAndroidLocationManager: true)
        .then((Position position) {
      setState(() {
        _currentPosition = position;
        print(_currentPosition!.latitude);
        _getAddressFromLatLon();
      });
    }).catchError((e) {
      Fluttertoast.showToast(msg: e.toString());
    });
  }
  _getAddressFromLatLon() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          _currentPosition!.latitude, _currentPosition!.longitude);

      Placemark place = placemarks[0];
      setState(() {
        _currentAddress =
        "${place.locality},${place.postalCode},${place.street},";
      });
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }
  String getGoogleMapsUrl() {
    if (_currentAddress != null) {
      return "https://www.google.com/maps/search/?api=1&query=$_currentAddress";
    } else {
      return "https://www.google.com/maps";
    }
  }
  Future<void> sendMessage(String message, String type) async {
    try {
      if (_currentAddress != null&& type != 'img') {
        message = "https://www.google.com/maps/search/?api=1&query=$_currentAddress";
      }
      else if (type == 'text') {
        // If the message type is 'text', use the user's text message
        message = message;
      }else if (type == 'img') {
        // If the message type is 'img', use the image message
        // You may need to adjust this based on how your image messages are stored or formatted
        message = "Image message: $message"; // Example: Concatenate 'Image message:' with the image URL or any relevant information
      }
      // else {
      //   message = "https://www.google.com/maps";
      // }

      await FirebaseFirestore.instance
          .collection("usres")
          .doc(widget.currentId)
          .collection("messages")
          .doc(widget.friendId)
          .collection("chats")
          .add({
        'senderId': widget.currentId,
        'receiverId': widget.friendId,
        'message': message,
        'type': type,
        'date': DateTime.now(),
      });

      await FirebaseFirestore.instance
          .collection("usres")
          .doc(widget.friendId)
          .collection("messages")
          .doc(widget.currentId)
          .collection("chats")
          .add({
        'senderId': widget.currentId,
        'receiverId': widget.friendId,
        'message': message,
        'type': type,
        'date': DateTime.now(),
      });

      _controller.clear();
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: EdgeInsets.all(0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                cursorColor: Colors.pink,
                decoration: InputDecoration(
                  hintText: 'Enter your message...',
                  fillColor: Colors.grey[100],
                  filled: true,
                  border: OutlineInputBorder(),
                  prefixIcon: IconButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => bottomSheet(context),
                        backgroundColor: Colors.transparent,
                      );
                    },
                    icon: Icon(
                      Icons.add_box_rounded,
                      color: Colors.pink,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () async {
                  message = _controller.text;
                  await sendMessage(message!, 'text');
                },
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.pink,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget bottomSheet(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.2,
      width: double.infinity,
      child: Card(
        margin: EdgeInsets.all(18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            chatsIcon(Icons.pin_drop, "Location", () async {
              await _getCurrentLocation();
              Future.delayed(Duration(seconds: 2), () {
                message = getGoogleMapsUrl();
                sendMessage(message!, "link");
              });
            }),
            chatsIcon(Icons.camera_alt, "Camera", () async{
              await getImageFromCamera();
            }),
            chatsIcon(Icons.insert_photo_rounded, "Gallery", () async{
              getImage();
            }),
          ],
        ),
      ),
    );
  }

  Widget chatsIcon(IconData icons, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.pink,
            child: Icon(icons),
          ),
          Text("$title"),
        ],
      ),
    );
  }
}
