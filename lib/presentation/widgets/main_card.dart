import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainCard extends StatefulWidget {
  final String imagrUrl;

  const MainCard({
    Key? key,
    required this.imagrUrl,
  }) : super(key: key);

  @override
  State<MainCard> createState() => _MainCardState();
}

class _MainCardState extends State<MainCard> {
  bool isLoading = false;

  Future<void> downloadAndSaveImage(String imageUrl) async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get the directory to store the image
      final Directory directory = await getApplicationDocumentsDirectory();
      final String fileName = imageUrl.split('/').last; // Use the last part of the URL as the file name
      final String filePath = '${directory.path}/$fileName';

      // Check if the file already exists
      final File file = File(filePath);
      if (!file.existsSync()) {
        // Download the image
        final response = await Dio().download(imageUrl, filePath);

        if (response.statusCode == 200) {
          debugPrint('Image downloaded and saved at $filePath');
        } else {
          debugPrint('Failed to download image. Status code: ${response.statusCode}');
          setState(() {
            isLoading = false;
          });
          return;
        }
      }

      // Save the local path to SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> favoriteImages = prefs.getStringList('favorites') ?? [];

      if (!favoriteImages.contains(filePath)) {
        favoriteImages.add(filePath);
        await prefs.setStringList('favorites', favoriteImages);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image added to favorites!')),
      );
    } catch (e) {
      debugPrint('Error downloading or saving image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add image to favorites.')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () async {
        await downloadAndSaveImage(widget.imagrUrl);
      },
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            width: 130,
            height: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10), // Use your constant if needed
              image: DecorationImage(
                image: NetworkImage(widget.imagrUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (isLoading)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 130,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
