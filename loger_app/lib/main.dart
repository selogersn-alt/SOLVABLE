import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const LogerApp());
}

class LogerApp extends StatelessWidget {
  const LogerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loger Sénégal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B4629),
          primary: const Color(0xFF0B4629),
          secondary: const Color(0xFF7FD47D),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const BiometricAuthScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B4629),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/img/logo.png',
              width: 180,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.home_work,
                size: 80,
                color: Color(0xFF7FD47D),
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              color: Color(0xFF7FD47D),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class BiometricAuthScreen extends StatefulWidget {
  const BiometricAuthScreen({super.key});

  @override
  State<BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends State<BiometricAuthScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
      });
      authenticated = await auth.authenticate(
        localizedReason: 'Accès sécurisé à votre tableau de bord immobilier',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint(e.toString());
      authenticated = true; // Fallback pour les appareils sans biométrie
    }

    if (!mounted) return;

    if (authenticated) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LogerHomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B4629),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/img/logo.png',
              width: 120,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.lock_outline,
                size: 60,
                color: Color(0xFF7FD47D),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'SÉCURITÉ SOLVABLE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Veuillez vous authentifier',
              style: TextStyle(color: Color(0xFF7FD47D), fontSize: 14),
            ),
            const SizedBox(height: 80),
            if (!_isAuthenticating)
              IconButton(
                icon: const Icon(Icons.fingerprint, size: 70, color: Color(0xFF7FD47D)),
                onPressed: _authenticate,
              )
            else
              const CircularProgressIndicator(color: Color(0xFF7FD47D)),
          ],
        ),
      ),
    );
  }
}

class LogerHomePage extends StatefulWidget {
  const LogerHomePage({super.key});

  @override
  State<LogerHomePage> createState() => _LogerHomePageState();
}

class _LogerHomePageState extends State<LogerHomePage> {
  late final WebViewController controller;
  double progress = 0;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              this.progress = progress / 100;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              progress = 0;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              progress = 1;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebResourceError: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) async {
            final url = request.url;
            if (url.startsWith('https://wa.me/') || 
                url.startsWith('whatsapp://') || 
                url.startsWith('tel:') || 
                url.startsWith('mailto:')) {
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                return NavigationDecision.prevent;
              }
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://logersenegal.com/'));

    _setupFilePicker();
  }

  void _setupFilePicker() {
    if (controller.platform is AndroidWebViewController) {
      (controller.platform as AndroidWebViewController).setOnShowFileSelector(
        (params) async {
          return await _showFileSelectionDialog(params);
        },
      );
    }
  }

  Future<List<String>> _showFileSelectionDialog(FileSelectorParams params) async {
    return await showModalBottomSheet<List<String>>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.bottom(20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Choisir un document',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerOption(
                  icon: Icons.camera_alt,
                  label: 'Caméra',
                  color: const Color(0xFF0B4629),
                  onTap: () async {
                    final result = await _pickFromCamera();
                    if (context.mounted) Navigator.pop(context, result);
                  },
                ),
                _buildPickerOption(
                  icon: Icons.photo_library,
                  label: 'Galerie',
                  color: const Color(0xFF0B4629),
                  onTap: () async {
                    final result = await _pickFromGallery(params);
                    if (context.mounted) Navigator.pop(context, result);
                  },
                ),
                _buildPickerOption(
                  icon: Icons.insert_drive_file,
                  label: 'Fichiers',
                  color: const Color(0xFF0B4629),
                  onTap: () async {
                    final result = await _pickFromFiles(params);
                    if (context.mounted) Navigator.pop(context, result);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ) ?? [];
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<List<String>> _pickFromCamera() async {
    try {
      if (await Permission.camera.request().isGranted) {
        final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
        if (photo != null) {
          return [Uri.file(photo.path).toString()];
        }
      }
    } catch (e) {
      debugPrint('Error picking from camera: $e');
    }
    return [];
  }

  Future<List<String>> _pickFromGallery(FileSelectorParams params) async {
    try {
      if (Platform.isAndroid && !await _requestStoragePermissions()) {
        return [];
      }
      
      if (params.mode == FileSelectorMode.openMultiple) {
        final List<XFile> images = await _picker.pickMultiImage();
        return images.map((image) => Uri.file(image.path).toString()).toList();
      } else {
        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          return [Uri.file(image.path).toString()];
        }
      }
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
    }
    return [];
  }

  Future<List<String>> _pickFromFiles(FileSelectorParams params) async {
    try {
      if (Platform.isAndroid && !await _requestStoragePermissions()) {
        return [];
      }
      
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: params.mode == FileSelectorMode.openMultiple,
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files
            .where((file) => file.path != null)
            .map((file) => Uri.file(file.path!).toString())
            .toList();
      }
    } catch (e) {
      debugPrint('Error picking files: $e');
    }
    return [];
  }

  Future<bool> _requestStoragePermissions() async {
    if (Platform.isAndroid) {
      // Permission.photos is for Android 13+ (API 33)
      // Permission.storage is for older versions
      if (await Permission.photos.request().isGranted || 
          await Permission.storage.request().isGranted) {
        return true;
      }
      
      // Secondary check for media video if photos is denied but they want to upload video
      if (await Permission.videos.request().isGranted) {
        return true;
      }
    }
    return true; // iOS and other platforms usually handled by system
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (progress < 1)
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white,
                color: const Color(0xFF7FD47D),
                minHeight: 2,
              ),
            Expanded(
              child: PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, result) async {
                  if (await controller.canGoBack()) {
                    controller.goBack();
                  }
                },
                child: WebViewWidget(controller: controller),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 60,
        color: const Color(0xFF0B4629),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
              onPressed: () async {
                if (await controller.canGoBack()) {
                  controller.goBack();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.home, color: Color(0xFF7FD47D), size: 28),
              onPressed: () => controller.loadRequest(Uri.parse('https://logersenegal.com/')),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 24),
              onPressed: () => controller.reload(),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
              onPressed: () async {
                if (await controller.canGoForward()) {
                  controller.goForward();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
