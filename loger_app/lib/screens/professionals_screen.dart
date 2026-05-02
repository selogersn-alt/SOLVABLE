import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class ExploreProfessionalsScreen extends StatefulWidget {
  const ExploreProfessionalsScreen({super.key});

  @override
  State<ExploreProfessionalsScreen> createState() => _ExploreProfessionalsScreenState();
}

class _ExploreProfessionalsScreenState extends State<ExploreProfessionalsScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _allPros = [];
  List<Map<String, dynamic>> _filteredPros = [];
  bool _isLoading = true;
  String _searchQuery = "";
  String _selectedRole = "TOUT";
  String _selectedCity = "SÉNÉGAL";
  List<String> _cities = ["SÉNÉGAL"];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.fetchProfessionals();
      final cities = await _apiService.fetchCities();
      
      // Filtrer uniquement les certifiés et trier par ordre alphabétique
      final certified = list.where((p) => p['is_verified_pro'] == true).toList();
      certified.sort((a, b) {
        final nameA = (a['company_name'] ?? a['full_name'] ?? "").toString().toLowerCase();
        final nameB = (b['company_name'] ?? b['full_name'] ?? "").toString().toLowerCase();
        return nameA.compareTo(nameB);
      });

      setState(() {
        _allPros = certified;
        _filteredPros = certified;
        _cities = ["SÉNÉGAL", ...cities.map((c) => c['name']!.toUpperCase())];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterPros() {
    setState(() {
      _filteredPros = _allPros.where((pro) {
        final matchesSearch = (pro['company_name'] ?? pro['full_name'] ?? "").toLowerCase().contains(_searchQuery.toLowerCase()) ||
                             (pro['coverage_area'] ?? "").toLowerCase().contains(_searchQuery.toLowerCase());
        
        final matchesRole = _selectedRole == "TOUT" || pro['role'] == _selectedRole;
        
        final matchesCity = _selectedCity == "SÉNÉGAL" || 
                           (pro['coverage_area'] ?? "").toUpperCase().contains(_selectedCity);

        return matchesSearch && matchesRole && matchesCity;
      }).toList();
    });
  }

  void _launchCall(String phone) async {
    final url = "tel:$phone";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Annuaire des Pros', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0B4629)))
              : _filteredPros.isEmpty 
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _filteredPros.length,
                    itemBuilder: (context, index) => _buildProCard(_filteredPros[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          TextField(
            onChanged: (v) {
              _searchQuery = v;
              _filterPros();
            },
            decoration: InputDecoration(
              hintText: "Rechercher une agence...",
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip("TOUT", "TOUT"),
                const SizedBox(width: 8),
                _buildFilterChip("AGENCE", "AGENCY"),
                const SizedBox(width: 8),
                _buildFilterChip("COURTIER", "BROKER"),
                const SizedBox(width: 8),
                _buildCityDropdown(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String role) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedRole = role);
        _filterPros();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0B4629) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.blueGrey,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCityDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCity,
          icon: const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFFDAA520)),
          items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))).toList(),
          onChanged: (v) {
            setState(() => _selectedCity = v!);
            _filterPros();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 80, color: Colors.blueGrey.shade100),
          const SizedBox(height: 16),
          const Text('Aucun professionnel ne correspond à vos critères', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildProCard(Map<String, dynamic> pro) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: const Color(0xFF0B4629).withValues(alpha: 0.1),
                backgroundImage: pro['profile_picture'] != null ? CachedNetworkImageProvider(pro['profile_picture']) : null,
                child: pro['profile_picture'] == null ? const Icon(Icons.account_balance_rounded, color: Color(0xFF0B4629), size: 30) : null,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pro['company_name'] ?? pro['full_name'] ?? "Sans nom",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF27C66E).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                          child: const Row(
                            children: [
                              Icon(Icons.verified_rounded, color: Color(0xFF27C66E), size: 14),
                              SizedBox(width: 4),
                              Text('CERTIFIÉ', style: TextStyle(color: Color(0xFF27C66E), fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: Colors.redAccent),
                        const SizedBox(width: 4),
                        Text(pro['coverage_area'] ?? 'Sénégal', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${pro['properties_count'] ?? 0} annonces actives', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey)),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _launchCall(pro['phone_number']),
                    icon: const CircleAvatar(backgroundColor: Color(0xFF0B4629), radius: 18, child: Icon(Icons.phone_rounded, color: Colors.white, size: 16)),
                  ),
                  IconButton(
                    onPressed: () {
                      // WhatsApp redirection is usually preferred for professionals
                      final phone = pro['phone_number'] ?? "";
                      launchUrl(Uri.parse("https://wa.me/$phone"));
                    },
                    icon: CircleAvatar(backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.1), radius: 18, child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366), size: 16)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
