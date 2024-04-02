import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:women_saftey/child/login_screen.dart';
import 'package:women_saftey/utils/constants.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:Center(
        child: TextButton(
        onPressed: ()async{
          try{
          await FirebaseAuth.instance.signOut();
          goTo(context, LoginScreen());
          }on FirebaseAuthException catch(e){
            dialogueBox(context, e.toString());
          }
        },
          child: Text("Sign-Out")
        ,),),
    );
  }
}
