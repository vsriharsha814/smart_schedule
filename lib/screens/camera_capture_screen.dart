import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Full-screen camera that always opens the rear lens.
/// Returns the captured image path via Navigator.pop, or null if cancelled.
class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  CameraController? _controller;
  bool _initializing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _error = 'No cameras found on this device.';
          _initializing = false;
        });
        return;
      }

      final rear = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(rear, ResolutionPreset.high);
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Camera error: $e';
        _initializing = false;
      });
    }
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null || controller.value.isTakingPicture) return;

    try {
      final file = await controller.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Capture failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Take photo'),
      ),
      body: _initializing
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: Center(child: CameraPreview(_controller!)),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: FloatingActionButton(
                          onPressed: _takePicture,
                          child: const Icon(Icons.camera),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
