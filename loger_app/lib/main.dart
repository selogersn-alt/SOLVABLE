import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'screens/property_list_screen.dart';
import 'screens/property_detail_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/add_property_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/nohan_chat_screen.dart';
import 'screens/blog_screen.dart';
import 'screens/professionals_screen.dart';
import 'screens/favorites_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  timeago.setLocaleMessages('fr', timeago.FrMessages());
  WidgetsFlutterBinding.ensureInitialized();

  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://example@sentry.io/123456'; // À remplacer par le vrai DNS
      options.tracesSampleRate = 1.0;
    },
    appRunner: () async {
      try {
        await Firebase.initializeApp();
        await NotificationService.initialize();
      } catch (e) {
        debugPrint('Firebase/Notification Init Error: $e');
      }

      await Hive.initFlutter();
      await Hive.openBox('properties_cache');

      runApp(const LogerApp());
    },
  );
}

class LogerApp extends StatelessWidget {
  const LogerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Loger Sénégal',
          themeMode: currentMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0B4629),
              primary: const Color(0xFF0B4629),
              secondary: const Color(0xFFDAA520),
              surface: Colors.white,
            ),
            textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: Color(0xFF0B4629),
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0B4629),
              brightness: Brightness.dark,
              primary: const Color(0xFF27C66E),
              secondary: const Color(0xFFF5C42F),
            ),
            textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF121212),
              elevation: 0,
              centerTitle: true,
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _handleStartup();
  }

  Future<void> _handleStartup() async {
    await AuthService().loadUser();
    final prefs = await SharedPreferences.getInstance();
    final bool isSecurityEnabled = prefs.getBool('use_biometrics') ?? false;

    if (isSecurityEnabled) {
      _checkBiometrics();
    } else {
      _navigateToHome();
    }
  }

  Future<void> _checkBiometrics() async {
    try {
      final bool canAuthenticate =
          await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (canAuthenticate) {
        final bool didAuthenticate = await auth.authenticate(
          localizedReason: 'Sécurisez votre accès à Loger Sénégal',
          options: const AuthenticationOptions(stickyAuth: false),
        );
        if (didAuthenticate) {
          _navigateToHome();
        } else {
          // Si l'utilisateur annule, on navigue quand même
          _navigateToHome();
        }
      } else {
        _navigateToHome();
      }
    } catch (e) {
      debugPrint('Biometric Error: $e');
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeInDown(
              child: Image.asset('assets/img/logo.png', width: 220),
            ),
            const SizedBox(height: 20),
            FadeInUp(
              child: const Text(
                "L'immobilier en toute confiance",
                style: TextStyle(
                  color: Color(0xFF0B4629),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 60),
            const SpinKitWave(color: Color(0xFFDAA520), size: 30.0),
          ],
        ),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  final AuthService _auth = AuthService();

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          PropertyListScreen(
            onPropertyTap: (property) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PropertyDetailScreen(property: property),
                ),
              );
            },
          ),
          const NohanChatScreen(),
          const FavoritesScreen(),
          const DashboardScreen(),
          const SettingsScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPropertyScreen()),
          );
        },
        backgroundColor: const Color(0xFFDAA520),
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 35),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        padding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onTabTapped,
          selectedItemColor: const Color(0xFF0B4629),
          unselectedItemColor: Colors.blueGrey.shade200,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 22),
              activeIcon: Icon(Icons.home_rounded, size: 26),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology_outlined, size: 22),
              activeIcon: Icon(Icons.psychology_rounded, size: 26),
              label: 'Nohan AI',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline_rounded, size: 22),
              activeIcon: Icon(Icons.favorite_rounded, size: 26),
              label: 'Favoris',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined, size: 22),
              activeIcon: Icon(Icons.dashboard_rounded, size: 26),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded, size: 22),
              activeIcon: Icon(Icons.person_rounded, size: 26),
              label: 'Compte',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final user = _auth.currentUser;
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF0B4629),
              image: DecorationImage(
                image: AssetImage('assets/img/logo.png'),
                opacity: 0.1,
                alignment: Alignment.centerRight,
              ),
            ),
            currentAccountPicture: (user?.profilePicture != null && user!.profilePicture!.isNotEmpty)
                ? CircleAvatar(
                    backgroundColor: const Color(0xFFDAA520),
                    backgroundImage: NetworkImage(user.profilePicture!),
                  )
                : CircleAvatar(
                    backgroundColor: const Color(0xFFDAA520),
                    child: Text(
                      (user?.firstName.isNotEmpty == true)
                          ? user!.firstName[0].toUpperCase()
                          : 'L',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
            accountName: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset('assets/img/logo.png', height: 25, color: Colors.white),
                const SizedBox(height: 8),
                Text(user != null ? '${user.firstName} ${user.lastName}' : 'Visiteur', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            accountEmail: Text(user?.phoneNumber ?? 'Loger Sénégal'),
          ),
          ListTile(
            leading: const Icon(Icons.article_outlined, color: Color(0xFF0B4629)),
            title: const Text('Blog Immobilier'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const BlogScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.people_outline, color: Color(0xFF0B4629)),
            title: const Text('Annuaire des Pros'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ExploreProfessionalsScreen()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help_outline_rounded, color: Color(0xFF0B4629)),
            title: const Text('Aide & Support'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded, color: Color(0xFF0B4629)),
            title: const Text('À propos'),
            onTap: () => Navigator.pop(context),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text("Version 2.12", style: TextStyle(color: Colors.grey, fontSize: 10)),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => launchUrl(Uri.parse('https://digitalh.net')),
                  child: const Text("Conçu par Digitalh", style: TextStyle(color: Color(0xFF0B4629), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          if (user != null)
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await _auth.logout();
                if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SplashScreen()));
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
