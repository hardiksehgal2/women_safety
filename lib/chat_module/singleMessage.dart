import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class SingleMessage extends StatelessWidget {
  final String? message;
  final bool? isMe;
  final String? image;
  final String? type;
  final String? friendName;
  final String? myName;
  final Timestamp? date;

  const SingleMessage({
    Key? key,
    this.message,
    this.isMe,
    this.image,
    this.type,
    this.friendName,
    this.myName,
    this.date,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    String formattedTime = '';

    if (date != null) {
      DateTime dateTime = date!.toDate();
      formattedTime = '${dateTime.hour}:${dateTime.minute}';
    }

    return type=='text'
        ? Container(
      constraints: BoxConstraints(maxWidth: size.width / 2),
      alignment: isMe ?? false ? Alignment.centerRight : Alignment.centerLeft,
      padding: EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          color: isMe ?? false ? Colors.pink[300] : Colors.grey[600],
          borderRadius: BorderRadius.only(
            topLeft: isMe ?? false ? Radius.circular(15) : Radius.zero,
            topRight: isMe ?? false ? Radius.zero : Radius.circular(15),
            bottomLeft: Radius.circular(15),
            bottomRight: Radius.circular(15),
          ),
        ),
        padding: EdgeInsets.all(10),
        constraints: BoxConstraints(maxWidth: size.width / 2),
        alignment: isMe ?? false ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          children: [

            Align(
              alignment: Alignment.centerRight,
              child: Text(
                message ?? '',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                formattedTime,
                style: TextStyle(fontSize: 10, color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    )
    :type=='img'?Container(
      height: size.height / 2.5,
      width: size.width,
      //constraints: BoxConstraints(maxWidth: size.width / 2),
      alignment: isMe ?? false ? Alignment.centerRight : Alignment.centerLeft,
      padding: EdgeInsets.all(10),
      child: Container(
        height: size.height / 2.5,
        width: size.width,
        decoration: BoxDecoration(
          color: isMe ?? false ? Colors.pink[300] : Colors.grey[600],
          borderRadius: BorderRadius.only(
            topLeft: isMe ?? false ? Radius.circular(15) : Radius.zero,
            topRight: isMe ?? false ? Radius.zero : Radius.circular(15),
            bottomLeft: Radius.circular(15),
            bottomRight: Radius.circular(15),
          ),
        ),
        // padding: EdgeInsets.all(10),
        constraints: BoxConstraints(maxWidth: size.width / 2),
        alignment: isMe ?? false ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          children: [

            CachedNetworkImage(
              imageUrl: message!,
              fit: BoxFit.cover,
              height: size.height / 3.62,
              width: size.width,
              placeholder: (context, url) =>
                  CircularProgressIndicator(),
              errorWidget: (context, url, error) =>
                  Icon(Icons.error),
            ),
            SizedBox(
              height: 10,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                formattedTime,
                style: TextStyle(fontSize: 10, color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    )
        : Container(
      constraints: BoxConstraints(maxWidth: size.width / 2),
      alignment: isMe ?? false ? Alignment.centerRight : Alignment.centerLeft,
      padding: EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          color: isMe ?? false ? Colors.pink[300] : Colors.grey[600],
          borderRadius: BorderRadius.only(
            topLeft: isMe ?? false ? Radius.circular(15) : Radius.zero,
            topRight: isMe ?? false ? Radius.zero : Radius.circular(15),
            bottomLeft: Radius.circular(15),
            bottomRight: Radius.circular(15),
          ),
        ),
        padding: EdgeInsets.all(10),
        constraints: BoxConstraints(maxWidth: size.width / 2),
        alignment: isMe ?? false ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          children: [

            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () async{
                  await launchUrl(Uri.parse("$message"));
                },
                child: Text(
                  message ?? '',
                  style: TextStyle(fontSize: 16, color: Colors.white,decoration: TextDecoration.underline,),
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                formattedTime,
                style: TextStyle(fontSize: 10, color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
