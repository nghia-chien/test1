const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { v4: uuidv4 } = require("uuid");

admin.initializeApp();

exports.uploadImage = functions.https.onCall(async (data, context) => {
  const { base64, fileName } = data;

  if (!base64 || !fileName) {
    throw new functions.https.HttpsError("invalid-argument", "Missing image data or filename.");
  }

  const buffer = Buffer.from(base64, "base64");
  const bucket = admin.storage().bucket();

  const file = bucket.file(`uploads/${fileName}`);
  await file.save(buffer, {
    metadata: {
      contentType: "image/jpeg",
      metadata: {
        firebaseStorageDownloadTokens: uuidv4(),
      },
    },
  });

  const downloadUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(file.name)}?alt=media`;
  return { downloadUrl };
});
