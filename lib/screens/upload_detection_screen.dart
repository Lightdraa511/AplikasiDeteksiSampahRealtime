import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/classifier.dart';
import '../widgets/detection_result_widget.dart';
import '../widgets/info_bottom_sheet.dart';

class UploadDetectionScreen extends StatefulWidget {
  const UploadDetectionScreen({super.key});

  @override
  State<UploadDetectionScreen> createState() => _UploadDetectionScreenState();
}

class _UploadDetectionScreenState extends State<UploadDetectionScreen> {
  File? _imageFile;
  ClassificationResult? _result;
  bool _isAnalyzing = false;
  WasteClassifier? _classifier;

  @override
  void initState() {
    super.initState();
    _initializeClassifier();
  }

  Future<void> _initializeClassifier() async {
    _classifier = WasteClassifier();
    await _classifier!.initialize();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _result = null;
        });
      }
    } catch (e) {
      _showError('Error memilih gambar: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageFile == null || _classifier == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final result = await _classifier!.classifyImage(_imageFile!);
      setState(() {
        _result = result;
      });
    } catch (e) {
      _showError('Error analisis: $e');
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showInfoBottomSheet() {
    if (_result != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => InfoBottomSheet(result: _result!),
      );
    }
  }

  void _reset() {
    setState(() {
      _imageFile = null;
      _result = null;
    });
  }

  @override
  void dispose() {
    _classifier?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF00BFA5),
              Color(0xFF1DE9B6),
              Color(0xFF64B5F6),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Upload Foto',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    if (_imageFile != null)
                      IconButton(
                        onPressed: _reset,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                      ),
                  ],
                ),
              ),

              Expanded(
                child: _imageFile == null
                    ? _buildUploadPrompt()
                    : _buildImagePreview(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.photo_library,
              size: 80,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'Pilih Foto',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Upload foto sampah dari galeri',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.image),
            label: const Text('Pilih dari Galeri'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF00BFA5),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                _imageFile!,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        if (_result == null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isAnalyzing ? null : _analyzeImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF00BFA5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
                child: _isAnalyzing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.analytics),
                          const SizedBox(width: 8),
                          Text(
                            'Analisis Foto',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          )
        else
          DetectionResultWidget(
            result: _result!,
            onInfoTap: _showInfoBottomSheet,
          ),
      ],
    );
  }
}