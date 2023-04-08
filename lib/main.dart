import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:developer';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const ImagePickerApp());
}

class ImagePickerApp extends StatefulWidget {
  const ImagePickerApp({Key? key}) : super(key: key);

  @override
  State<ImagePickerApp> createState() => _ImagePickerAppState();
}

class _ImagePickerAppState extends State<ImagePickerApp> {
  File? _image;
  String? _response;
  Map<String, dynamic>? _prediction;

  Future getImage(ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(
          source: source, imageQuality: 40, maxHeight: 250, maxWidth: 250);
      if (image == null) return;

      final tempImage = File(image.path);
      String base64Image = base64Encode(tempImage.readAsBytesSync());

      Uri url = Uri.parse('https://flutter-ml.onrender.com/imgprocess');
      final response = await http.post(
        url,
        body: jsonEncode({
          'image': base64Image,
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      setState(() {
        _image = tempImage;
        _response = response.body;
        // assign to _response a specific key from the response body
        try {
          _prediction = jsonDecode(_response!);
        } catch (e) {
          log('Failed to decode JSON: $base64Image');
          _prediction = {'output': 'Failed to decode JSON'};
        }
        ;
      });
    } on PlatformException catch (e) {
      log('Failed to pick image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.teal,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Center(
              child: Text('Flutter + Machine Learning',
                  style: GoogleFonts.poppins())),
        ),
        body: Center(
          child: Column(
            children: [
              const Padding(
                padding:
                    EdgeInsets.only(top: 20, bottom: 30, left: 30, right: 30),
                child: Center(
                  child: Text(
                    '📷  Take a picture of a hand-written digit between 0 and 9\n\n🔢  The digit must be centered and in black color\n\n🧮  The app will try to predict the digit (as best as it could 😁)',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _image != null
                      ? Column(
                          children: [
                            Image.file(_image!,
                                width: 250, height: 250, fit: BoxFit.cover),
                            const SizedBox(height: 10),
                            Text('Predicted Value: ${_prediction!['output']}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                )),
                          ],
                        )
                      : Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.image_outlined,
                              size: 100, color: Colors.grey[600]),
                        ),
                  const SizedBox(height: 20),
                  CustomButton(
                    title: 'Pick from Gallery',
                    icon: Icons.image_outlined,
                    onClick: () => getImage(ImageSource.gallery),
                  ),
                  CustomButton(
                    title: 'Capture image',
                    icon: Icons.camera_alt_outlined,
                    onClick: () => getImage(ImageSource.camera),
                  ),
                  const SizedBox(height: 40),
                  const Text('Made by:'),
                  const Text('Reeman Singh | BSIT-2A'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget CustomButton({
  required String title,
  required IconData icon,
  required VoidCallback onClick,
}) {
  return Container(
      width: 200,
      child: ElevatedButton(
          onPressed: onClick,
          child: Row(children: [
            Icon(icon),
            const SizedBox(width: 15),
            Text(title),
          ])));
}
