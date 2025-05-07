import 'dart:developer';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:qrvault/routes.dart';

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
        automaticallyImplyLeading: false, 
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: Text(
          AppLocalizations.of(context)!.appTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.language);
            },
          ),
        ],
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    _controller != null &&
                    _controller!.value.isInitialized) {

                  var camera = _controller?.value;
                  // fetch screen size
                  final size = MediaQuery.of(context).size;

                  // calculate scale depending on screen and camera ratios
                  // this is actually size.aspectRatio / (1 / camera.aspectRatio)
                  // because camera preview size is received as landscape
                  // but we're calculating for portrait orientation
                  var scale = size.aspectRatio * camera!.aspectRatio;

                  // to prevent scaling down, invert the value
                  if (scale < 1) scale = 1 / scale;

                  return Transform.scale(
                      scale: scale,
                      child: Center(
                        child: CameraPreview(_controller!),
                      ));
                } else if (snapshot.hasError) {
                  return Center(
                      child: Text(AppLocalizations.of(context)!.errorInitializingCamera('${snapshot.error}')));
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
           Navigator.pushNamed(context, AppRoutes.create);
          },
          icon: const Icon(Icons.add_circle_outline),
          label: Text(AppLocalizations.of(context)!.create),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
      ),
    );
  }
}
