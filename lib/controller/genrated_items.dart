import 'dart:typed_data';

// Custom image widget without sqflite dependency
import 'package:ai_image_makerr/utils/app_color.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SafeCachedNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const SafeCachedNetworkImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  State<SafeCachedNetworkImage> createState() => _SafeCachedNetworkImageState();
}

class _SafeCachedNetworkImageState extends State<SafeCachedNetworkImage> {
  late Future<Uint8List> _imageFuture;
  Map<String, Uint8List> _imageCache = {};

  @override
  void initState() {
    super.initState();
    _imageFuture = _loadImage();
  }

  @override
  void didUpdateWidget(SafeCachedNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _imageFuture = _loadImage();
    }
  }

  Future<Uint8List> _loadImage() async {
    // Check cache first
    if (_imageCache.containsKey(widget.imageUrl)) {
      return _imageCache[widget.imageUrl]!;
    }

    try {
      final response = await http.get(Uri.parse(widget.imageUrl));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        // Cache the image
        _imageCache[widget.imageUrl] = bytes;
        return bytes;
      } else {
        throw Exception('Failed to load image');
      }
    } catch (e) {
      print(' Error loading image: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.placeholder ??
              Container(
                color: AppColors.grey200,
                child: Center(child: CircularProgressIndicator()),
              );
        } else if (snapshot.hasError) {
          return widget.errorWidget ??
              Container(
                color: AppColors.grey200,
                child: Center(child: Icon(Icons.error, color: AppColors.red)),
              );
        } else if (snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
          );
        } else {
          return Container();
        }
      },
    );
  }
}
