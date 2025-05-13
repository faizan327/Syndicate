const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.createUser = functions.https.onCall(async (data, context) => {
  // Verify the caller is an admin
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }
  const callerUid = context.auth.uid;
  const callerDoc = await admin.firestore().collection('users').doc(callerUid).get();
  if (!callerDoc.exists || callerDoc.data().role !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Must be an admin');
  }

  const { email, password, username, bio, role, profileUrl } = data;

  // Create user in Firebase Authentication
  const userRecord = await admin.auth().createUser({
    email,
    password,
  });

  // Create Firestore document
  await admin.firestore().collection('users').doc(userRecord.uid).set({
    email,
    username,
    bio,
    role: role || 'user',
    profile: profileUrl || 'https://robohash.org/default.png',
    followers: [],
    following: [],
    isSuspended: false,
  });

  return { uid: userRecord.uid };
});