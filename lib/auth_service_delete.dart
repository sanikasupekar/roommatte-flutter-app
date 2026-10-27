import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthServiceDelete {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> deleteUserAccount() async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        String uid = user.uid;

        
        
        await _firestore.collection('users').doc(uid).delete();
        await _firestore.collection('students').doc(uid).delete();

        
        
        await user.delete();
        
        print("Gmail aani Firestore data successfully delete jhaala.");
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        
        
        throw 'Security sathi tumhala parat ekda login karun he karaave lagel.';
      }
      throw e.message ?? "Kahitari chukle aahe.";
    } catch (e) {
      throw "Error: $e";
    }
  }
}