import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/classifier.dart';
import '../widgets/detection_result_widget.dart';
import '../widgets/info_bottom_sheet.dart';

class RealtimeDetectionScreen extends StatefulWidget {
  const RealtimeDetectionScreen({super.key});

  @override
  State<RealtimeDetectionScreen> createState() => _RealtimeDetectionScreenState();
}

class _RealtimeDetectionScreenState extends State<RealtimeDetectionScreen> {
  CameraController? _cameraController;
  WasteClassifier? _classifier;
  
  bool _isInitialized = false;
  bool _isDetecting = false;
  ClassificationResult? _currentResult;
  Timer? _detectionTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        _showError('Izin kamera diperlukan');
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showError('Kamera tidak ditemukan');
        return;
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      await _setupAutoFocus();  // Setup auto focus

      _classifier = WasteClassifier();
      await _classifier!.initialize();

      _detectionTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        _detectFromCamera();
      });

      setState(() {
        _isInitialized = true;
      });

    } catch (e) {
      _showError('Error: $e');
    }
  }

  Future<void> _setupAutoFocus() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    try {
      // Set camera focus mode to auto
      await _cameraController!.setFocusMode(FocusMode.auto);
      
      // Set exposure mode to auto
      await _cameraController!.setExposureMode(ExposureMode.auto);
      
      // Optional: Set focus point to center
      try {
        final size = _cameraController!.value.previewSize;
        if (size != null) {
          await _cameraController!.setFocusPoint(Offset(
            size.width / 2,
            size.height / 2,
          ));
        }
      } catch (e) {
        // Some devices might not support setting focus point
        print('Focus point not supported: $e');
      }
    } catch (e) {
      print('Error setting up camera features: $e');
    }
  }

  Future<void> _detectFromCamera() async {
    if (_isDetecting || _cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    _isDetecting = true;

    try {
      final image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      
      final result = await _classifier!.classifyImageBytes(bytes);
      
      if (mounted) {
        setState(() {
          _currentResult = result;
        });
      }

    } catch (e) {
      print('Detection error: $e');
    } finally {
      _isDetecting = false;
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      Navigator.pop(context);
    }
  }

  void _showInfoBottomSheet() {
    if (_currentResult != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => InfoBottomSheet(result: _currentResult!),
      );
    }
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _cameraController?.dispose();
    _classifier?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isInitialized && _cameraController != null)
            Positioned.fill(
              child: GestureDetector(
                onTapDown: (details) async {
                  final size = _cameraController!.value.previewSize;
                  if (size != null) {
                    final offset = Offset(
                      details.localPosition.dx,
                      details.localPosition.dy,
                    );
                    try {
                      await _cameraController!.setFocusPoint(offset);
                      await _cameraController!.setExposurePoint(offset);
                    } catch (e) {
                      print('Error setting focus/exposure point: $e');
                    }
                  }
                },
                child: CameraPreview(_cameraController!),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Material(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.videocam, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Deteksi Real-time',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),

          if (_currentResult != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: DetectionResultWidget(
                result: _currentResult!,
                onInfoTap: _showInfoBottomSheet,
              ),
            ),

          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _cornerWidget(),
                      Transform.rotate(
                        angle: 1.5708,
                        child: _cornerWidget(),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Transform.rotate(
                        angle: -1.5708,
                        child: _cornerWidget(),
                      ),
                      Transform.rotate(
                        angle: 3.14159,
                        child: _cornerWidget(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cornerWidget() {
    return Container(
      width: 30,
      height: 30,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white, width: 3),
          left: BorderSide(color: Colors.white, width: 3),
        ),
      ),
    );
  }
}