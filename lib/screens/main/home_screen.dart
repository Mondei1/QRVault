import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class HomeScreenView extends StatefulWidget {
  const HomeScreenView({super.key});

  @override
  State<HomeScreenView> createState() => _HomeScreenViewState();
}

class _HomeScreenViewState extends State<HomeScreenView> {
  CameraController? _controller; 
  Future<void>? _initializeControllerFuture; 

  @override
  void initState() {
    super.initState();
    _initializeCamera(); 
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        log("No cameras available");
        return;
      }
      final firstCamera = cameras.first;

      _controller = CameraController(
        firstCamera,
        ResolutionPreset.medium, 
      );

      _initializeControllerFuture = _controller!.initialize();
      _initializeControllerFuture!.then((_) {
        if (!mounted) {
          return;
        }
        setState(() {}); 
      });
    } catch (e) {
      log("Error initializing camera: $e");
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: Text(
          'QRVault',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            //TODO: Implement onPressedSettings
          },
        ),
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done && _controller != null && _controller!.value.isInitialized) {
                  return CameraPreview(_controller!);
                } else if (snapshot.hasError) {
                    return Center(child: Text("Error initializing camera: ${snapshot.error}"));
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 30.0),
        child: FloatingActionButton.extended(
          onPressed: () {
           //TODO: Implement onPressedCreate
          },
          icon: const Icon(Icons.add),
          label: const Text('Create'),
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }
} 