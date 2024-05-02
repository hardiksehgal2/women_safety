import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:women_saftey/chat_module/message_text_field.dart';
import 'package:women_saftey/chat_module/singleMessage.dart';
import '../utils/constants.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String friendId;
  final String friendName;

  const ChatScreen({Key? key, required this.currentUserId, required this.friendId, required this.friendName}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? type;
  String? myname;
  bool isLoading = true; // Add a loading state

  Future<void> getStatus() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('usres').doc(widget.currentUserId).get();
      if (snapshot.exists) {
        setState(() {
          type = snapshot.get('type');
          myname = snapshot.get('name');
          isLoading = false; // Set loading state to false when data is loaded
        });
      } else {
        // Document does not exist, handle this case appropriately
        setState(() {
          isLoading = false; // Set loading state to false even if document does not exist
        });
        print('User document does not exist for ID: ${widget.currentUserId}');
      }
    } catch (e) {
      // Handle Firestore error
      setState(() {
        isLoading = false; // Set loading state to false in case of error
      });
      print('Error fetching user data: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    getStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink,
        title: widget.friendName.text.make(),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator while fetching data
          : Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('usres')
                  .doc(widget.currentUserId)
                  .collection('messages')
                  .doc(widget.friendId)
                  .collection('chats')
                  .orderBy('date', descending: true) // Sort messages by date in descending order
                  .snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  if (snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: type == "parent"
                          ? "Chat with Child".text.xl2.make()
                          : "Chat with Parent".text.xl2.make(),
                    );
                  }
                  return Container(
                    child: ListView.builder(
                      reverse: true, // Reverse the list to show newer messages at the bottom
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (BuildContext context, int index) {
                        bool isMe = snapshot.data!.docs[index]['senderId'] == widget.currentUserId;
                        final data = snapshot.data!.docs[index];
                        return Dismissible(
                          key: UniqueKey() ,
                          onDismissed: (direction) async{
                            await FirebaseFirestore.instance
                                .collection('usres')
                                .doc(widget.currentUserId)
                                .collection('messages')
                                .doc(widget.friendId)
                                .collection('chats')
                                .doc(data.id)
                                .delete();
                            await FirebaseFirestore.instance
                                .collection('usres')
                                .doc(widget.friendId)
                                .collection('messages')
                                .doc(widget.currentUserId)
                                .collection('chats')
                                .doc(data.id)
                                .delete().then((value) => Fluttertoast.showToast(msg: 'message deleted successfully'));
                          },
                          child: SingleMessage(
                            message: data['message'],
                            date: data['date'],
                            isMe: isMe,
                            friendName: widget.friendName,
                            myName: myname,
                            type: data['type'],
                          ),
                        );
                      },
                    ),
                  );
                }
                return progressIndicator(context);
              },
            ),
          ),
          MessageTextField(
            currentId: widget.currentUserId,
            friendId: widget.friendId,
          ),
        ],
      ),
    );
  }
}
