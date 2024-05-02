import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';

import '../../chat_module/chat_screen.dart';
import '../../utils/constants.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink,
        title: "SELECT GUARDIAN".text.make(),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error.toString()}'));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No data available'));
          } else {
            return ListView.builder(

              itemCount: snapshot.data!.docs.length,
              itemBuilder: (BuildContext context, int index) {
                final d = snapshot.data!.docs[index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    color: Color.fromARGB(255, 250, 163, 192),
                    child: ListTile(
                      onTap: (){
                        goTo(context, ChatScreen(
                            currentUserId: FirebaseAuth.instance.currentUser!.uid,
                            friendId: d.id,
                            friendName: d['name']));
                      },
                      title: Text(d['name']),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
