import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animate_do/animate_do.dart';
import '../models/property_model.dart';
import '../services/api_service.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'search_results_screen.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import 'solvency_docs_screen.dart';

class PropertyListScreen extends StatefulWidget {
  final Function(Property) onPropertyTap;
  const PropertyListScreen({super.key, required this.onPropertyTap});

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  final ApiService _apiService = ApiService();
  static const _pageSize = 10;
  final PagingController<int, Property> _pagingController = PagingController(firstPageKey: 1);
  final TextEditingController _searchController = TextEditingController();
  
  String _selectedCity = 'TOUT';
  String _selectedType = 'TOUT';
  String _selectedCategory = 'TOUT';
  String _selectedNeighborhood = 'TOUT';
  Timer? _refreshTimer;
  
  final Map<String, String> _categoryMap = {
    'TOUT': 'TOUT',
    'LOCATION': 'RENT',
    'VENTE': 'SALE',
    'LOCATION_VACANCES': 'VACATION',
  };

  final Map<String, String> _cityMap = {
    'TOUT': 'TOUT',
    'DAKAR': 'DAKAR',
    'THIES': 'THIES',
    'MBOUR': 'MBOUR',
    'SALY': 'SALY',
    'TOUBA': 'TOUBA',
    'RUFISQUE': 'RUFISQUE',
    'SAINT-LOUIS': 'SAINT_LOUIS',
    'SOMONE': 'SOMONE',
    'NGAPAROU': 'NGAPAROU'
  };

  final Map<String, String> _typeMap = {
    'TOUT': 'TOUT',
    'APPARTEMENT': 'APARTMENT',
    'VILLA': 'VILLA',
    'MAISON': 'MAISON',
    'STUDIO': 'STUDIO',
    'TERRAIN': 'TERRAIN',
    'BUREAU': 'BUREAU',
    'COMMERCIAL': 'COMMERCIAL',
    'IMMEUBLE': 'IMMEUBLE'
  };

  late final List<String> _cities = _cityMap.keys.toList();
  late final List<String> _types = _typeMap.keys.toList();
  final List<String> _neighborhoods = [
    'TOUT', 'Almadies', 'Plateau', 'Mermoz', 'Ngor', 'Ouakam', 'Point E', 'Fann', 'Liberté 6', 'Sacré Coeur', 'Keur Massar', 'Guediawaye', 'Pikine'
  ];

  @override
  void initState() {
    super.initState();
    // Load cached properties first
    final cached = _apiService.getCachedProperties();
    if (cached.isNotEmpty) {
      _pagingController.itemList = cached;
    }
    
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newItems = await _apiService.fetchProperties(
        page: pageKey,
        city: _selectedCity == 'TOUT' ? null : _cityMap[_selectedCity],
        propertyType: _selectedType == 'TOUT' ? null : _typeMap[_selectedType],
        neighborhood: _selectedNeighborhood == 'TOUT' ? null : _selectedNeighborhood,
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
      );
      final isLastPage = !newItems['next'];
      if (isLastPage) {
        _pagingController.appendLastPage(newItems['properties'] as List<Property>);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(newItems['properties'] as List<Property>, nextPageKey);
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
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // CUSTOM APP BAR LIKE IMAGE
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Image.asset('assets/img/logo.png', fit: BoxFit.contain),
            ),
            title: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                children: [
                  TextSpan(text: 'Loger'),
                  TextSpan(text: 'Sénégal', style: TextStyle(color: Color(0xFF27C66E))),
                ],
              ),
            ),
            actions: const [],
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
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0B4629), Color(0xFF062B1A)],
                      ),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF0B4629).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Logo en filigrane (Watermark)
                        Positioned(
                          top: 80,
                          right: -40,
                          child: Opacity(
                            opacity: 0.1,
                            child: Image.asset('assets/img/logo.png', width: 300),
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
                                    style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, height: 1.1),
                                    children: [
                                      TextSpan(text: "Trouvez votre "),
                                      TextSpan(text: "logement idéal ", style: TextStyle(color: Color(0xFFF5C42F))),
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
                                  style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500),
                                ),
                              ),
                              const SizedBox(height: 120), // Espace pour la carte
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
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 40, offset: const Offset(0, 15)),
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
                            const SizedBox(height: 16),
                            ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SearchResultsScreen(
                                        city: _selectedCity == 'TOUT' ? null : _cityMap[_selectedCity],
                                        type: _selectedType == 'TOUT' ? null : _typeMap[_selectedType],
                                        category: _selectedCategory == 'TOUT' ? null : _selectedCategory,
                                        search: _searchController.text.isNotEmpty ? _searchController.text : null,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF5C42F),
                                  foregroundColor: const Color(0xFF0B4629),
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  minimumSize: const Size(double.infinity, 56),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                child: const Text('RECHERCHER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1)),
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

          // BLOC NILS (Identique à la page d'accueil web)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shield_outlined, color: Colors.redAccent, size: 28),
                        const SizedBox(width: 12),
                        const Text(
                          "Système NILS",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Analysez la solvabilité d'un candidat avant de signer.",
                      style: TextStyle(color: Colors.blueGrey, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Nom ou Numéro CNI",
                        prefixIcon: const Icon(Icons.search, size: 20),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final Uri url = Uri.parse('https://logersenegal.com/nils/recherche/');
                        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                          debugPrint('Could not launch $url');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B4629),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      child: const Text("ANALYSER LE PROFIL", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
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
                      Text('À la Une', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                      Text('Sélection de prestige', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Row(
                      children: const [
                        Text('Voir tout', style: TextStyle(color: Color(0xFF27C66E), fontWeight: FontWeight.bold)),
                        Icon(Icons.chevron_right_rounded, color: Color(0xFF27C66E)),
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
              itemBuilder: (context, item, index) => AnimationConfiguration.staggeredList(
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
              newPageProgressIndicatorBuilder: (_) => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
              noItemsFoundIndicatorBuilder: (_) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Aucun bien trouvé'),
                    TextButton(onPressed: () => _refresh(), child: const Text('Recharger')),
                  ],
                ),
              ),
              firstPageErrorIndicatorBuilder: (context) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Erreur lors du chargement des annonces'),
                    const SizedBox(height: 10),
                    ElevatedButton(onPressed: () => _refresh(), child: const Text('Réessayer')),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.category_outlined, color: Color(0xFFF5C42F), size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(16),
                hint: const Text('Je cherche...', style: TextStyle(color: Colors.blueGrey)),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.blueGrey),
                items: _categoryMap.keys.map((String cat) {
                  return DropdownMenuItem<String>(
                    value: cat,
                    child: Text(
                      cat, 
                      style: const TextStyle(
                        color: Colors.black, 
                        fontWeight: FontWeight.w600,
                        fontSize: 15
                      )
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF27C66E), size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Mots-clés (Villa, piscine...)',
                hintStyle: TextStyle(color: Colors.blueGrey, fontSize: 15, fontWeight: FontWeight.w500),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _refresh(),
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
          const Icon(Icons.location_on_outlined, color: Color(0xFF27C66E), size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCity,
                isExpanded: true,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(16),
                hint: const Text('Où cherchez-vous ?', style: TextStyle(color: Colors.blueGrey)),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.blueGrey),
                items: _cities.map((String city) {
                  return DropdownMenuItem<String>(
                    value: city,
                    child: Text(
                      city, 
                      style: const TextStyle(
                        color: Colors.black, 
                        fontWeight: FontWeight.w600,
                        fontSize: 15
                      )
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
                hint: const Text('Type de bien', style: TextStyle(color: Colors.blueGrey)),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.blueGrey),
                items: _types.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(
                      type, 
                      style: const TextStyle(
                        color: Colors.black, 
                        fontWeight: FontWeight.w600,
                        fontSize: 15
                      )
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

  Widget _buildNeighborhoodSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: Color(0xFF27C66E), size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedNeighborhood,
                isExpanded: true,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(16),
                hint: const Text('Quartier', style: TextStyle(color: Colors.blueGrey)),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.blueGrey),
                items: _neighborhoods.map((String neighborhood) {
                  return DropdownMenuItem<String>(
                    value: neighborhood,
                    child: Text(
                      neighborhood, 
                      style: const TextStyle(
                        color: Colors.black, 
                        fontWeight: FontWeight.w600,
                        fontSize: 15
                      )
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedNeighborhood = newValue;
                    });
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: CachedNetworkImage(
                    imageUrl: p.images.isNotEmpty ? p.images.first.imageUrl : '',
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          p.listingCategoryDisplay.toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFF27C66E), borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          timeago.format(p.createdAt, locale: 'fr'),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () async {
                      final success = await _apiService.toggleFavorite(p.id.toString());
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Favoris mis à jour'), duration: Duration(seconds: 1)),
                        );
                      }
                    },
                    child: const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 18,
                      child: Icon(Icons.favorite_border_rounded, size: 18, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('${p.neighborhood}, ${p.city}', style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '${NumberFormat.decimalPattern('fr').format(p.price)} F',
                        style: const TextStyle(color: Color(0xFF27C66E), fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                      const Spacer(),
                      const Icon(Icons.bed_rounded, size: 16, color: Colors.blueGrey),
                      const SizedBox(width: 4),
                      Text('${p.bedrooms}', style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
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

  Widget _buildSkeletonLoader() {
    return Container(height: 200, color: Colors.grey[100]);
  }
}
