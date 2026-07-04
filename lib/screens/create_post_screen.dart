import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/post_service.dart';
import '../themes/purple_theme.dart';
import '../utils/image_picker_stub.dart'
    if (dart.library.html) '../utils/image_picker_web.dart';

class CreatePostScreen extends StatefulWidget {
  final String postType; // 'instagram' or 'twitter'

  const CreatePostScreen({super.key, this.postType = 'instagram'});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  bool _isPosting = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await ImagePickerHelper.pickImage();
    if (result == null || !mounted) return;

    setState(() {
      if (result["isWeb"] == true) {
        _selectedImageBytes = result["bytes"] as Uint8List?;
        _selectedImageFile = null;
      } else {
        _selectedImageFile = result["file"] as File?;
        _selectedImageBytes = null;
      }
    });
  }

  Future<void> _createPost() async {
    if (_captionController.text.trim().isEmpty &&
        _selectedImageFile == null &&
        _selectedImageBytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add a caption or image')),
        );
      }
      return;
    }

    setState(() => _isPosting = true);

    try {
      final post = await PostService.createPost(
        caption: _captionController.text.trim(),
        imageBytes: _selectedImageBytes,
        imageFile: _selectedImageFile,
        postType: widget.postType,
      );

      if (post != null && mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully!')),
        );
      } else {
        throw Exception('Failed to create post');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating post: $e')),
        );
      }
    }
  }

@override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F12) : Colors.white,
      appBar: AppBar(
        title: Text(
          widget.postType == 'twitter' ? "Create Tweet" : "Create Post",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1A1A1F) : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
actions: [
          TextButton(
            onPressed: _isPosting ? null : _createPost,
            child: _isPosting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    "Post",
                    style: TextStyle(
                      color: PurpleTheme.primaryPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image preview or picker
            if (_selectedImageFile != null || _selectedImageBytes != null)
              Stack(
                alignment: Alignment.topRight,
                children: [
Container(
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark 
                            ? const Color(0x1AFFFFFF) 
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: kIsWeb && _selectedImageBytes != null
                          ? Image.memory(_selectedImageBytes!, fit: BoxFit.cover)
                          : _selectedImageFile != null
                              ? Image.file(_selectedImageFile!, fit: BoxFit.cover)
                              : const SizedBox(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? Colors.black87 : Colors.black54,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedImageFile = null;
                        _selectedImageBytes = null;
                      });
                    },
                  ),
                ],
              )
else
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark 
                          ? const Color(0x1AFFFFFF) 
                          : Colors.grey[300]!, 
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate, 
                        size: 64, 
                        color: isDark ? Colors.grey[400] : Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to add photo',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

// Caption input
            TextField(
              controller: _captionController,
              maxLines: 5,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: "Write a caption...",
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark 
                        ? const Color(0x1AFFFFFF) 
                        : Colors.grey[300]!,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark 
                        ? const Color(0x1AFFFFFF) 
                        : Colors.grey[300]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: PurpleTheme.primaryPurple,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.all(12),
                filled: true,
                fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            // Add image button
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.photo_library, color: isDark ? Colors.white : Colors.black),
              label: Text(
                'Add Photo',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: PurpleTheme.primaryPurple,
                  width: 1.5,
                ),
                foregroundColor: PurpleTheme.primaryPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
