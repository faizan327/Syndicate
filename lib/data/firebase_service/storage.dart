import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
// import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';

class StorageMethod {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  var uid = Uuid().v4();

  Future<File?> reencodeVideo(File inputFile) async {
    try {
      if (!await inputFile.exists()) {
        print("Input file does not exist: ${inputFile.path}");
        return null;
      }
      print("Input file: ${inputFile.path}, size: ${await inputFile.length()} bytes");

      final Directory tempDir = await getTemporaryDirectory();
      final String outputPath = '${tempDir.path}/reencoded_$uid.mp4';
      print("Output path: $outputPath");

      // Optimized FFmpeg command for Instagram Reels-like playback
      String command =
          '-i "${inputFile.path}" '
          '-c:v libx264 -preset veryfast -tune fastdecode ' // Fast encoding, quick decoding
          '-profile:v main -level 3.1 ' // Main profile for better compatibility
          '-vf "scale=w=trunc(iw/2)*2:h=-2" ' // Maintain original aspect ratio
          '-b:v 2500k ' // 2.5 Mbps bitrate, suitable for 720p vertical video
          '-r 30 ' // 30fps for smooth playback
          '-c:a aac -b:a 96k ' // 96kbps audio, lightweight yet clear
          '-movflags +faststart ' // Enable fast start for streaming
          '-y "$outputPath"'; // Overwrite output file
      print("Executing FFmpeg command: $command");

      // // final session = await FFmpegKit.execute(command);
      // final returnCode = await session.getReturnCode();
      // final logs = await session.getAllLogs();

      // print("FFmpeg logs:");
      // for (var log in logs) {
      //   print(log.getMessage());
      // }
      //
      // if (returnCode?.isValueSuccess() == true) {
      //   print("Video re-encoding successful");
      // } else {
      //   print("Video re-encoding failed with return code: $returnCode");
      //   return null;
      // }

      final File reencodedFile = File(outputPath);
      if (await reencodedFile.exists()) {
        print("Re-encoded file found at: $outputPath, size: ${await reencodedFile.length()} bytes");
        return reencodedFile;
      } else {
        print("Re-encoded file not found at: $outputPath");
        return null;
      }
    } catch (e) {
      print("Error during video re-encoding: $e");
      return null;
    }
  }
  // Updated upload method
  Future<String> uploadImageToStorage(String name, File file, {bool isVideo = false}) async {
    File fileToUpload = file;

    if (isVideo) {
      final reencodedFile = await reencodeVideo(file);
      if (reencodedFile == null) {
        throw Exception("Video re-encoding failed");
      }
      fileToUpload = reencodedFile;
    }

    Reference ref = _storage.ref().child(name).child(_auth.currentUser!.uid).child(uid);
    UploadTask uploadTask = ref.putFile(fileToUpload);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<String> uploadStoryMedia({
    required String userId,
    required File file,
    required String mediaType, // 'image' or 'video'
  }) async {
    try {
      String storyId = uid;
      Reference ref = _storage.ref().child('stories').child(userId).child('$storyId.$mediaType');
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading story media: $e');
      rethrow;
    }
  }


}