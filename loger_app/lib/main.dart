import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'screens/property_list_screen.dart';
import 'screens/property_detail_screen.dart';
import 'screens/professionals_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/add_property_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/nohan_chat_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Loger Sénégal',
      theme: ThemeData(
        useMaterial3: true,
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
          options: const AuthenticationOptions(stickyAuth: true),
        );
        if (didAuthenticate) _navigateToHome();
      } else {
        _navigateToHome();
      }
    } catch (e) {
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
      appBar: AppBar(
        title: Image.asset('assets/img/logo.png', height: 40),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF0B4629)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0B4629)),
            onPressed: () {},
          ),
        ],
      ),
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
            decoration: const BoxDecoration(color: Color(0xFF0B4629)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: const Color(0xFFDAA520),
              child: Text(
                user?.firstName.substring(0, 1).toUpperCase() ?? 'L',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            accountName: Text(user != null ? '${user.firstName} ${user.lastName}' : 'Visiteur', style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(user?.phoneNumber ?? 'Loger Sénégal'),
          ),
          ListTile(
            leading: const Icon(Icons.article_outlined, color: Color(0xFF0B4629)),
            title: const Text('Blog Immobilier'),
            onTap: () {
              Navigator.pop(context);
              // Navigation vers Blog
            },
          ),
          ListTile(
            leading: const Icon(Icons.shield_outlined, color: Color(0xFF0B4629)),
            title: const Text('Liste Noire (Sécurité)'),
            onTap: () {
              Navigator.pop(context);
              // Navigation vers Blacklist
            },
          ),
          ListTile(
            leading: const Icon(Icons.people_outline, color: Color(0xFF0B4629)),
            title: const Text('Annuaire des Pros'),
            onTap: () {
              Navigator.pop(context);
              _onTabTapped(1); // Nohan ou autre
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

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final ApiService _apiService = ApiService();
  List<Property> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.fetchFavorites();
      setState(() {
        _favorites = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Favoris', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _favorites.isEmpty 
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _favorites.length,
              itemBuilder: (context, index) {
                final p = _favorites[index];
                return _buildFavoriteCard(p);
              },
            ),
    );
  }

  Widget _buildFavoriteCard(Property p) {
    return Card(
      margin: const EdgeInsets.bottom(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(p.images.isNotEmpty ? p.images.first.imageUrl : '', width: 70, height: 70, fit: BoxFit.cover),
        ),
        title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${p.price} F'),
        trailing: IconButton(
          icon: const Icon(Icons.favorite, color: Colors.red),
          onPressed: () async {
            await _apiService.toggleFavorite(p.id);
            _loadFavorites();
          },
        ),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PropertyDetailScreen(property: p))),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border_rounded, size: 80, color: Colors.blueGrey.shade100),
          const SizedBox(height: 16),
          const Text('Vos coups de coeur s\'afficheront ici', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
