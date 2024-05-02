import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';

import '../../utils/constants.dart';
import '../chat_module/chat_screen.dart';
import '../child/login_screen.dart';

class ParentHomeScreen extends StatelessWidget {
  const ParentHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(child: Container(),
            ),
            ListTile(
              title: TextButton(
                onPressed: ()async{
                  try{
                    await FirebaseAuth.instance.signOut();
                    goTo(context, LoginScreen());
                  }on FirebaseAuthException catch(e){
                    dialogueBox(context, e.toString());
                  }
                },
                child: Text("Sign-Out")
                ,),
            ),
          ],
        ),
      ),

      appBar: AppBar(
        backgroundColor: Colors.pink,
        title: const Text("SELECT GUARD"),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('usres')
            .where('type', isEqualTo: 'child')
            .where('parentEmail', isEqualTo: FirebaseAuth.instance.currentUser?.email??" ")
            .snapshots(),
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
                      title: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(d['name']),
                      ),
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
