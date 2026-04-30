import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animate_do/animate_do.dart';
import '../models/property_model.dart';
import '../services/api_service.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'search_results_screen.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'blog_screen.dart';
import 'professionals_screen.dart';

class PropertyListScreen extends StatefulWidget {
  final Function(Property) onPropertyTap;
  const PropertyListScreen({super.key, required this.onPropertyTap});

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  final ApiService _apiService = ApiService();
  final PagingController<int, Property> _pagingController = PagingController(
    firstPageKey: 1,
  );
  final TextEditingController _searchController = TextEditingController();

  String _selectedCity = 'TOUT';
  String _selectedType = 'TOUT';
  String _selectedCategory = 'TOUT';
  String _selectedNeighborhood = 'TOUT';

  final Map<String, String> _categoryMap = {
    'TOUT': 'TOUT',
    'LOCATION': 'RENT',
    'VENTE': 'SALE',
    'LOCATION_VACANCES': 'VACATION',
  };

  final Map<String, String> _typeMap = {'TOUT': 'TOUT'};
  final Map<String, String> _cityMap = {'TOUT': 'TOUT'};

  List<String> _cities = ['TOUT'];
  List<String> _types = ['TOUT'];

  @override
  void initState() {
    super.initState();
    // IMPORTANT: Ajouter le listener AVANT de charger le cache
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    _loadMetadata();
    // Afficher le cache en attendant le chargement réseau
    final cached = _apiService.getCachedProperties();
    if (cached.isNotEmpty) {
      debugPrint('Loaded ${cached.length} properties from cache');
    }
  }

  Future<void> _loadMetadata() async {
    try {
      final cities = await _apiService.fetchCities();
      final types = await _apiService.fetchPropertyTypes();
      
      if (mounted) {
        setState(() {
          for (var c in cities) {
            _cityMap[c['name']!.toUpperCase()] = c['id']!;
          }
          for (var t in types) {
            _typeMap[t['name']!.toUpperCase()] = t['id']!;
          }
          _cities = _cityMap.keys.toList();
          _types = _typeMap.keys.toList();
        });
      }
    } catch (e) {
      debugPrint('Metadata Load Error: $e');
    }
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newItems = await _apiService.fetchProperties(
        page: pageKey,
        city: _selectedCity == 'TOUT' ? null : _cityMap[_selectedCity],
        propertyType: _selectedType == 'TOUT' ? null : _typeMap[_selectedType],
        listingCategory: _selectedCategory == 'TOUT' ? null : _categoryMap[_selectedCategory],
        neighborhood: _selectedNeighborhood == 'TOUT'
            ? null
            : _selectedNeighborhood,
        search: _searchController.text.isNotEmpty
            ? _searchController.text
            : null,
      );
      final isLastPage = !newItems['next'];
      if (isLastPage) {
        _pagingController.appendLastPage(
          newItems['properties'] as List<Property>,
        );
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(
          newItems['properties'] as List<Property>,
          nextPageKey,
        );
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    _pagingController.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // WATERMARK LOGO IN BACKGROUND
          Positioned(
            top: 200,
            right: -50,
            child: Opacity(
              opacity: 0.03,
              child: Image.asset('assets/img/logo.png', width: 300),
            ),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
        slivers: [
          // CUSTOM APP BAR LIKE IMAGE
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            pinned: true,
            centerTitle: true,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: Color(0xFF0B4629)),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/img/logo.png', height: 30),
                const SizedBox(width: 8),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    children: [
                      TextSpan(text: 'Loger'),
                      TextSpan(
                        text: 'Sénégal',
                        style: TextStyle(color: Color(0xFF27C66E)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0B4629)),
                onPressed: () {},
              ),
            ],
          ),

          // HERO SECTION WITH SEARCH CARD (Identique au site web)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 640, // Augmenté pour inclure le nouveau sélecteur et NILS
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Background Image Container avec Dégradé Premium
                  Container(
                    height: 520,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(40),
                      ),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0B4629), Color(0xFF062B1A)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0B4629).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Logo en filigrane (Watermark) - Positionnement amélioré pour tablettes
                        Positioned(
                          top: 60,
                          right: -30,
                          child: Opacity(
                            opacity: 0.08,
                            child: Image.asset(
                              'assets/img/logo.png',
                              width: MediaQuery.of(context).size.width * 0.7,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FadeInDown(
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: const TextSpan(
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                      height: 1.1,
                                    ),
                                    children: [
                                      TextSpan(text: "Trouvez votre "),
                                      TextSpan(
                                        text: "logement idéal ",
                                        style: TextStyle(
                                          color: Color(0xFFF5C42F),
                                        ),
                                      ),
                                      TextSpan(text: "au Sénégal"),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              FadeInUp(
                                child: const Text(
                                  "La plateforme immobilière la plus sécurisée pour louer ou acheter en toute sérénité.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 120,
                              ), // Espace pour la carte
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Floating Search Card (Moteur Complet)
                  Positioned(
                    bottom: 0,
                    left: 20,
                    right: 20,
                    child: FadeInUp(
                      delay: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0B4629).withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildCategorySelector(), // NOUVEAU
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            _buildTypeSelector(),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            _buildCitySelector(),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            _buildNeighborhoodSelector(),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SearchResultsScreen(
                                      city: _selectedCity == 'TOUT'
                                          ? null
                                          : _cityMap[_selectedCity],
                                      type: _selectedType == 'TOUT'
                                          ? null
                                          : _typeMap[_selectedType],
                                      category: _selectedCategory == 'TOUT'
                                          ? null
                                          : _categoryMap[_selectedCategory],
                                      neighborhood: _selectedNeighborhood == 'TOUT'
                                          ? null
                                          : _selectedNeighborhood,
                                      search: _searchController.text.isNotEmpty
                                          ? _searchController.text
                                          : null,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF5C42F),
                                foregroundColor: const Color(0xFF0B4629),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'RECHERCHER',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // QUICK LINKS (Annuaire & Blog)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildQuickAction(
                      title: "Annuaire Pro",
                      subtitle: "Agences certifiées",
                      icon: Icons.business_center_rounded,
                      color: const Color(0xFF0B4629),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ExploreProfessionalsScreen())),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickAction(
                      title: "Blog Immo",
                      subtitle: "Conseils & Guides",
                      icon: Icons.article_rounded,
                      color: const Color(0xFFDAA520),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const BlogScreen())),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),

          // FEATURED SECTION HEADER
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'À la Une',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Sélection de prestige',
                        style: TextStyle(
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Row(
                      children: const [
                        Text(
                          'Voir tout',
                          style: TextStyle(
                            color: Color(0xFF27C66E),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF27C66E),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          PagedSliverList<int, Property>(
            pagingController: _pagingController,
            builderDelegate: PagedChildBuilderDelegate<Property>(
              itemBuilder: (context, item, index) =>
                  AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 600),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildPropertyCard(item),
                        ),
                      ),
                    ),
                  ),
              firstPageProgressIndicatorBuilder: (_) => _buildSkeletonLoader(),
              newPageProgressIndicatorBuilder: (_) => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
              noItemsFoundIndicatorBuilder: (_) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Aucun bien trouvé'),
                    TextButton(
                      onPressed: () => _refresh(),
                      child: const Text('Recharger'),
                    ),
                  ],
                ),
              ),
              firstPageErrorIndicatorBuilder: (context) => _buildErrorWidget(
                _pagingController.error?.toString() ?? 'Erreur inconnue',
                _refresh,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
          
          // FOOTER WITH LOGO
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Image.asset('assets/img/logo.png', height: 40, color: Colors.blueGrey.withValues(alpha: 0.2)),
                  const SizedBox(height: 12),
                  const Text(
                    "LOGER SÉNÉGAL ™",
                    style: TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Le futur de l'immobilier au Sénégal",
                    style: TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 9,
                    ),
                  ),
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

  Widget _buildCategorySelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.category_outlined,
            color: Color(0xFFF5C42F),
            size: 22,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(16),
                hint: const Text(
                  'Je cherche...',
                  style: TextStyle(color: Colors.blueGrey),
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.blueGrey,
                ),
                items: _categoryMap.keys.map((String cat) {
                  return DropdownMenuItem<String>(
                    value: cat,
                    child: Text(
                      cat,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                    _refresh();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeighborhoodSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.near_me_rounded, color: Color(0xFF0B4629), size: 20),
          const SizedBox(width: 12),
          const Text('Quartier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
          const Spacer(),
          Expanded(
            flex: 2,
            child: TextField(
              onChanged: (val) => setState(() => _selectedNeighborhood = val.isEmpty ? 'TOUT' : val),
              decoration: const InputDecoration(
                hintText: 'Ex: Almadies',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0B4629)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCitySelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            color: Color(0xFF27C66E),
            size: 22,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCity,
                isExpanded: true,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(16),
                hint: const Text(
                  'Où cherchez-vous ?',
                  style: TextStyle(color: Colors.blueGrey),
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.blueGrey,
                ),
                items: _cities.map((String city) {
                  return DropdownMenuItem<String>(
                    value: city,
                    child: Text(
                      city,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCity = newValue;
                    });
                    _refresh();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.home_outlined, color: Color(0xFF27C66E), size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedType,
                isExpanded: true,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(16),
                hint: const Text(
                  'Type de bien',
                  style: TextStyle(color: Colors.blueGrey),
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.blueGrey,
                ),
                items: _types.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(
                      type,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedType = newValue;
                    });
                    _refresh();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildPropertyCard(Property p) {
    return GestureDetector(
      onTap: () => widget.onPropertyTap(p),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20),
          ],
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
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey.shade100, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                    errorWidget: (context, url, error) => Container(color: Colors.grey.shade100, child: const Icon(Icons.broken_image_outlined, color: Colors.grey)),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      p.propertyTypeDisplay.toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0B4629)),
                    ),
                  ),
                ),
                if (p.listingCategory == 'SALE')
                  Positioned(
                    top: 45,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5C42F),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'A VENDRE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0B4629)),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF062B1A).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${NumberFormat('#,###', 'fr_FR').format(p.price)} FCFA',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Color(0xFF27C66E), shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF062B1A), height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF27C66E)),
                      const SizedBox(width: 6),
                      Text(
                        p.owner.companyName ?? 'LOGER SÉNÉGAL ™',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF27C66E)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 16, color: Colors.blueGrey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${p.neighborhood}, ${p.city}',
                                style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF27C66E)),
                          const SizedBox(width: 4),
                          Text(
                            timeago.format(p.createdAt, locale: 'fr'),
                            style: const TextStyle(fontSize: 13, color: Color(0xFF27C66E), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 16),
                  // Actions Row
                  Row(
                    children: [
                      _buildMiniAction(Icons.message_rounded, const Color(0xFF25D366)),
                      const SizedBox(width: 8),
                      _buildMiniAction(Icons.phone_rounded, const Color(0xFF007BFF)),
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text('Détails', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                            SizedBox(width: 8),
                            Icon(Icons.chevron_right_rounded, size: 18),
                          ],
                        ),
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

  Widget _buildMiniAction(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

   Widget _buildSkeletonLoader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String errorMessage, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded, color: Colors.red.shade300, size: 40),
            ),
            const SizedBox(height: 24),
            const Text(
              'Connexion impossible',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF062B1A)),
            ),
            const SizedBox(height: 12),
            const Text(
              'Vérifiez votre connexion Internet et réessayez.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('RÉESSAYER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B4629),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.blueGrey, fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
