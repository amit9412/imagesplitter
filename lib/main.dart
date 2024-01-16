// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as imglib;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ImageSplitScreen(),
    );
  }
}

class ImageSplitScreen extends StatefulWidget {
  const ImageSplitScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ImageSplitScreenState createState() => _ImageSplitScreenState();
}

class _ImageSplitScreenState extends State<ImageSplitScreen> {
  File? _image;
  int numberOfPieces = 1;
  List<File> splitImages = [];

  Future getImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        splitImages = [];
      } else {
        const AlertDialog.adaptive(semanticLabel: 'No image selected.');
        print('No image selected.');
      }
    });
  }

  Future<void> splitAndSaveImage() async {
    if (_image == null) return;

    imglib.Image? image = decodeImage(_image!);

    int x = 0, y = 0;
    int width = (image!.width / numberOfPieces).floor();
    int height = (image.height / numberOfPieces).floor();
    for (int i = 0; i < numberOfPieces; i++) {
      for (int j = 0; j < numberOfPieces; j++) {
        imglib.Image croppedImage =
            imglib.copyCrop(image, x: x, y: y, width: width, height: height);

        // Save the split image to local storage
        File splitImageFile = await saveImageToStorage(encodeJpg(croppedImage));

        // Add the split image file to the list
        splitImages.add(splitImageFile);
        x += width;
      }
      x = 0;
      y += height;
    }
  }

  Future<File> saveImageToStorage(Uint8List imageBytes) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;

    File splitImageFile =
        File('$appDocPath/split_image_${splitImages.length + 1}.jpg');
    await splitImageFile.writeAsBytes(imageBytes);

    return splitImageFile;
  }

  imglib.Image? decodeImage(File imageFile) {
    List<int> imageBytes = imageFile.readAsBytesSync();
    Uint8List uint8List = Uint8List.fromList(imageBytes);
    imglib.Image? image = imglib.decodeImage(uint8List);

    return image;
  }

  Uint8List encodeJpg(imglib.Image image) {
    return Uint8List.fromList(imglib.encodeJpg(image));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Uploader and Splitter'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _image == null
                  ? const Text('No image selected.')
                  : Image.file(
                      _image!,
                      height: 200,
                      width: 200,
                    ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: getImage,
                child: const Text('Select Image'),
              ),
              const SizedBox(height: 20),
              const Text('Enter the number of pieces:'),
              const SizedBox(height: 10),
              TextField(
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    numberOfPieces = int.tryParse(value) ?? 1;
                  });
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  await splitAndSaveImage();
                  setState(() {});
                },
                child: const Text('Split Image'),
              ),
              const SizedBox(height: 20),
              splitImages.isEmpty
                  ? Container()
                  : GridView.builder(
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                      ),
                      itemCount: splitImages.length,
                      itemBuilder: (context, index) {
                        return Image.file(
                          splitImages[index],
                          height: 100,
                          width: 100,
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
