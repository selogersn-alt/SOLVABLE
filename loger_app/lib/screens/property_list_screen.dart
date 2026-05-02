import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/property_model.dart';
import '../models/alert_model.dart';
import '../services/api_service.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'search_results_screen.dart';
import 'blog_screen.dart';
import 'professionals_screen.dart';
import 'favorites_screen.dart';
import '../config/app_constants.dart';
import 'package:timeago/timeago.dart' as timeago;

class PropertyListScreen extends StatefulWidget {
  final Function(Property) onPropertyTap;
  const PropertyListScreen({super.key, required this.onPropertyTap});

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  final ApiService _apiService = ApiService();
  final PagingController<int, Property> _pagingController = PagingController(firstPageKey: 1);
  final TextEditingController _searchController = TextEditingController();

  String _selectedCity = 'TOUT';
  String _selectedType = 'TOUT';
  String _selectedCategory = 'TOUT';
  final String _selectedNeighborhood = 'Tous les quartiers';

  final Map<String, String> _categoryMap = {
    'TOUT': 'TOUT',
    'A louer': 'RENT',
    'A vendre': 'SALE',
    'Meublée (Vacances)': 'FURNISHED',
  };

  List<Property> _boostedProperties = [];
  final PageController _carouselController = PageController();
  Timer? _carouselTimer;
  int _carouselIndex = 0;

  Set<String> _favoriteIds = {};
  List<PropertyAlert> _alerts = [];

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener(_fetchPage);
    _loadBoostedProperties();
    _loadFavorites();
    _loadAlerts();
  }

  Future<void> _loadBoostedProperties() async {
    try {
      final result = await _apiService.fetchProperties(page: 1);
      final all = result['properties'] as List<Property>;
      if (mounted) {
        setState(() => _boostedProperties = all.where((p) => p.isBoosted).take(10).toList());
        _startCarouselTimer();
      }
    } catch (_) {}
  }

  void _startCarouselTimer() {
    _carouselTimer?.cancel();
    if (_boostedProperties.isEmpty) return;
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_carouselController.hasClients) return;
      _carouselIndex = (_carouselIndex + 1) % _boostedProperties.length;
      _carouselController.animateToPage(_carouselIndex,
          duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
    });
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('favorite_ids') ?? [];
    if (mounted) setState(() => _favoriteIds = ids.toSet());
  }

  Future<void> _toggleFavorite(Property p) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favoriteIds.contains(p.id)) {
        _favoriteIds.remove(p.id);
      } else {
        _favoriteIds.add(p.id);
      }
    });
    await prefs.setStringList('favorite_ids', _favoriteIds.toList());
    if (_favoriteIds.contains(p.id) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Ajouté aux favoris'),
        action: SnackBarAction(label: 'Voir', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()))),
      ));
    }
  }

  Future<void> _loadAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('property_alerts');
    if (raw != null && mounted) setState(() => _alerts = PropertyAlert.decodeList(raw));
  }

  Future<void> _saveAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('property_alerts', PropertyAlert.encodeList(_alerts));
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final city = _selectedCity == 'TOUT' ? null : _selectedCity;
      final type = _selectedType == 'TOUT' ? null : _selectedType;
      final cat = _categoryMap[_selectedCategory] == 'TOUT' ? null : _categoryMap[_selectedCategory];
      final nbhd = _selectedNeighborhood == 'Tous les quartiers' ? null : _selectedNeighborhood;
      
      final newItemsRaw = await _apiService.fetchProperties(
        page: pageKey, city: city, propertyType: type,
        listingCategory: cat, neighborhood: nbhd,
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
      );
      
      final List<Property> allFetched = newItemsRaw['properties'] as List<Property>;
      // Filtrer les annonces boostées pour ne pas les doubler avec le carousel
      final filtered = allFetched.where((p) => !p.isBoosted).toList();
      
      final isLastPage = !newItemsRaw['next'];
      if (isLastPage) {
        _pagingController.appendLastPage(filtered);
      } else {
        _pagingController.appendPage(filtered, pageKey + 1);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  void _launchPhone(String phone) async {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('tel:+$clean');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  void _launchWhatsApp(String phone) async {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showAlertsModal() {
    String? alertCity;
    String? alertCat;
    final minCtrl = TextEditingController();
    final maxCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setM) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Expanded(child: Text('Créer une alerte', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ]),
              const Text('Recevez une alerte quand un bien correspond à vos critères.', style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Ville', border: OutlineInputBorder()),
                items: AppConstants.cities.entries.map((e) => DropdownMenuItem(value: e.key == 'TOUT' ? null : e.key, child: Text(e.value))).toList(),
                onChanged: (v) => setM(() => alertCity = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Catégorie', border: OutlineInputBorder()),
                items: AppConstants.listingCategories.entries.map((e) => DropdownMenuItem(value: e.key == 'TOUT' ? null : e.key, child: Text(e.value))).toList(),
                onChanged: (v) => setM(() => alertCat = v),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: minCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prix min (FCFA)', border: OutlineInputBorder()))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: maxCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prix max (FCFA)', border: OutlineInputBorder()))),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B4629), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: () {
                    final parts = [
                      if (alertCity != null) AppConstants.cities[alertCity],
                      if (alertCat != null) AppConstants.listingCategories[alertCat],
                    ];
                    final alert = PropertyAlert(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      label: parts.isEmpty ? 'Alerte générale' : parts.join(' · '),
                      city: alertCity, listingCategory: alertCat,
                      minPrice: double.tryParse(minCtrl.text),
                      maxPrice: double.tryParse(maxCtrl.text),
                      createdAt: DateTime.now(),
                    );
                    setState(() => _alerts.add(alert));
                    _saveAlerts();
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alerte créée !')));
                  },
                  child: const Text("CRÉER L'ALERTE", style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
              if (_alerts.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Mes alertes actives', style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                ..._alerts.map((a) => ListTile(
                  leading: const Icon(Icons.notifications_active_rounded, color: Color(0xFFF5C42F)),
                  title: Text(a.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () {
                    setState(() => _alerts.remove(a));
                    _saveAlerts();
                    Navigator.pop(ctx);
                  }),
                )),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselController.dispose();
    _pagingController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() => _pagingController.refresh();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 200, right: -50,
            child: Opacity(opacity: 0.03, child: Image.asset('assets/img/logo.png', width: 300)),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.white, elevation: 0, pinned: true, centerTitle: true, automaticallyImplyLeading: false,
                title: Row(mainAxisSize: MainAxisSize.min, children: [
                  Image.asset('assets/img/logo.png', height: 30),
                  const SizedBox(width: 8),
                  RichText(text: const TextSpan(style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black), children: [TextSpan(text: 'Loger'), TextSpan(text: 'Sénégal', style: TextStyle(color: Color(0xFF27C66E)))])),
                ]),
                actions: [
                  IconButton(
                    icon: Stack(clipBehavior: Clip.none, children: [
                      const Icon(Icons.notifications_none_rounded, color: Color(0xFF0B4629)),
                      if (_alerts.isNotEmpty)
                        Positioned(right: -2, top: -2, child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFF5C42F), shape: BoxShape.circle), child: Center(child: Text('${_alerts.length}', style: const TextStyle(fontSize: 6, color: Colors.black, fontWeight: FontWeight.bold))))),
                    ]),
                    onPressed: _showAlertsModal,
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 600,
                  child: Stack(clipBehavior: Clip.none, children: [
                    Container(
                      height: 480, width: double.infinity, margin: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
                        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0B4629), Color(0xFF062B1A)]),
                      ),
                      child: Stack(children: [
                        Positioned(top: 60, right: -30, child: Opacity(opacity: 0.08, child: Image.asset('assets/img/logo.png', width: MediaQuery.of(context).size.width * 0.7, fit: BoxFit.contain))),
                        Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          FadeInDown(child: RichText(textAlign: TextAlign.center, text: const TextSpan(style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, height: 1.1), children: [TextSpan(text: "Trouvez votre "), TextSpan(text: "logement idéal ", style: TextStyle(color: Color(0xFFF5C42F))), TextSpan(text: "au Sénégal")]))),
                          const SizedBox(height: 16),
                          FadeInUp(child: const Text("La plateforme immobilière la plus sécurisée pour louer ou acheter en toute sérénité.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14))),
                          const SizedBox(height: 100),
                        ])),
                      ]),
                    ),
                    Positioned(
                      bottom: 0, left: 20, right: 20,
                      child: FadeInUp(delay: const Duration(milliseconds: 300), child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))]),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          _buildDropdown("Ville", _selectedCity, AppConstants.cities.keys.toList(), (v) => setState(() => _selectedCity = v!)),
                          const SizedBox(height: 12),
                          _buildDropdown("Type", _selectedType, AppConstants.propertyTypes.keys.toList(), (v) => setState(() => _selectedType = v!)),
                          const SizedBox(height: 12),
                          _buildDropdown("Catégorie", _selectedCategory, _categoryMap.keys.toList(), (v) => setState(() => _selectedCategory = v!)),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => SearchResultsScreen(
                                city: _selectedCity == 'TOUT' ? null : _selectedCity,
                                type: _selectedType == 'TOUT' ? null : _selectedType,
                                category: _categoryMap[_selectedCategory] == 'TOUT' ? null : _categoryMap[_selectedCategory],
                                search: _searchController.text.isNotEmpty ? _searchController.text : null,
                              )));
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF5C42F), foregroundColor: const Color(0xFF0B4629), minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                            child: const Text('RECHERCHER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                          ),
                        ]),
                      )),
                    ),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                  child: Row(children: [
                    Expanded(child: _buildQuickAction(title: "Annuaire Pro", subtitle: "Agences certifiées", icon: Icons.business_center_rounded, color: const Color(0xFF0B4629), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ExploreProfessionalsScreen())))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildQuickAction(title: "Blog Immo", subtitle: "Conseils & Guides", icon: Icons.article_rounded, color: const Color(0xFFDAA520), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const BlogScreen())))),
                  ]),
                ),
              ),
              if (_boostedProperties.isNotEmpty)
                SliverToBoxAdapter(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Text("À la Une (Boosté)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF062B1A)))),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: PageView.builder(
                        controller: _carouselController,
                        itemCount: _boostedProperties.length,
                        onPageChanged: (i) => _carouselIndex = i,
                        itemBuilder: (context, index) {
                          final p = _boostedProperties[index];
                          return GestureDetector(
                            onTap: () {
                              _apiService.cachePropertyDetails(p); // Cache agressive
                              widget.onPropertyTap(p);
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 15),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: CachedNetworkImage(
                                      imageUrl: p.images.isNotEmpty ? p.images.first.imageUrl : '',
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      memCacheWidth: 800,
                                      maxWidthDiskCache: 1200,
                                      placeholder: (context, url) => Container(color: Colors.black12, child: const Center(child: CircularProgressIndicator())),
                                      errorWidget: (context, url, error) => const Icon(Icons.error),
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(15),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: const Color(0xFFF5C42F), borderRadius: BorderRadius.circular(5)),
                                          child: const Text("BOOSTÉ", style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(p.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        Text("${NumberFormat('#,###').format(p.price)} FCFA", style: const TextStyle(color: Color(0xFF27C66E), fontWeight: FontWeight.w900, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ]),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
              PagedSliverList<int, Property>(
                pagingController: _pagingController,
                builderDelegate: PagedChildBuilderDelegate<Property>(
                  itemBuilder: (context, item, index) => AnimationConfiguration.staggeredList(position: index, duration: const Duration(milliseconds: 600), child: SlideAnimation(verticalOffset: 50.0, child: FadeInAnimation(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: _buildPropertyCard(item))))),
                  firstPageProgressIndicatorBuilder: (_) => _buildSkeletonLoader(),
                  newPageProgressIndicatorBuilder: (_) => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                  noItemsFoundIndicatorBuilder: (_) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('Aucun bien trouvé'), TextButton(onPressed: () => _refresh(), child: const Text('Recharger'))])),
                  firstPageErrorIndicatorBuilder: (context) => _buildErrorWidget(_pagingController.error?.toString() ?? 'Erreur inconnue', _refresh),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Image.asset('assets/img/logo.png', height: 35, color: Colors.blueGrey.withValues(alpha: 0.15)),
                      const SizedBox(height: 16),
                      const Text("LOGER SÉNÉGAL ™", style: TextStyle(color: Colors.blueGrey, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      const SizedBox(height: 8),
                      const Text("Version 2.12", style: TextStyle(color: Colors.blueGrey, fontSize: 10)),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => launchUrl(Uri.parse('https://digitalh.net')),
                        child: const Text(
                          "Conçu avec ❤️ par Digitalh",
                          style: TextStyle(color: Color(0xFF0B4629), fontSize: 11, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.1))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 20)),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          Text(subtitle, style: const TextStyle(color: Colors.blueGrey, fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: 5, itemBuilder: (context, index) => Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), child: Container(height: 200, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(24)))));
  }

  Widget _buildErrorWidget(String message, VoidCallback onRetry) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.error_outline_rounded, size: 60, color: Colors.redAccent), const SizedBox(height: 16), Text(message, style: const TextStyle(color: Colors.blueGrey)), TextButton(onPressed: onRetry, child: const Text('RÉESSAYER'))]));
  }

  Widget _buildPropertyCard(Property p) {
    final isFav = _favoriteIds.contains(p.id);
    return GestureDetector(
      onTap: () {
        _apiService.cachePropertyDetails(p); // Mise en cache agressive
        widget.onPropertyTap(p);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 32), // Augmenté pour mieux délimiter
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 25, offset: const Offset(0, 10)),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: CachedNetworkImage(
                    imageUrl: p.images.isNotEmpty ? p.images.first.imageUrl : '',
                    height: 240, // Légèrement augmenté
                    width: double.infinity,
                    fit: BoxFit.cover,
                    memCacheWidth: 800, // Adaptatif 3G/EDGE
                    maxWidthDiskCache: 1200,
                    placeholder: (context, url) => Container(color: Colors.grey.shade100, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                    errorWidget: (context, url, error) => Container(color: Colors.grey.shade100, child: const Icon(Icons.broken_image_outlined, color: Colors.grey)),
                  ),
                ),
                Positioned(
                  top: 12, left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(8)),
                    child: Text(p.propertyTypeDisplay.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0B4629))),
                  ),
                ),
                Positioned(
                  bottom: 12, right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFF062B1A).withValues(alpha: 0.85), borderRadius: BorderRadius.circular(12)),
                    child: Text('${NumberFormat('#,###', 'fr_FR').format(p.price)} FCFA', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                  ),
                ),
                Positioned(
                  top: 12, right: 12,
                  child: GestureDetector(
                    onTap: () => _toggleFavorite(p),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: isFav ? Colors.red.withValues(alpha: 0.9) : Colors.black26, shape: BoxShape.circle),
                      child: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        timeago.format(p.createdAt, locale: 'fr'),
                        style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      if (p.owner.isVerifiedPro)
                        const Row(
                          children: [
                            Icon(Icons.verified_rounded, color: Color(0xFF27C66E), size: 14),
                            SizedBox(width: 4),
                            Text('VÉRIFIÉ', style: TextStyle(color: Color(0xFF27C66E), fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(p.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF062B1A), height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: const Color(0xFF27C66E).withValues(alpha: 0.1),
                        child: const Icon(Icons.person_rounded, size: 14, color: Color(0xFF27C66E)),
                      ),
                      const SizedBox(width: 8),
                      Text(p.owner.companyName ?? p.owner.displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildActionBtn(Icons.chat_bubble_outline_rounded, const Color(0xFF25D366), () => _launchWhatsApp(p.owner.phoneNumber), label: "WhatsApp"),
                      const SizedBox(width: 12),
                      _buildActionBtn(Icons.phone_iphone_rounded, const Color(0xFF007BFF), () => _launchPhone(p.owner.phoneNumber)),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () => widget.onPropertyTap(p),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B4629),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('VOIR', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, Color color, VoidCallback onTap, {String? label}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            if (label != null) ...[
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(15)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.map((i) {
            String display = i;
            if (label == "Ville") display = AppConstants.cities[i] ?? i;
            if (label == "Type") display = AppConstants.propertyTypes[i] ?? i;
            return DropdownMenuItem(value: i, child: Text(display, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
