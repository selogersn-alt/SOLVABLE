import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../models/property_model.dart';
import '../services/api_service.dart';
import 'property_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  
  List<Property> _myProperties = [];
  List<dynamic> _myBookings = [];
  List<dynamic> _myVisits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final properties = await _apiService.fetchMyProperties();
      final bookings = await _apiService.fetchMyBookings();
      final visits = await _apiService.fetchMyVisits();
      
      setState(() {
        _myProperties = properties;
        _myBookings = bookings;
        _myVisits = visits;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Mon Dashboard', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0B4629),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF27C66E),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Annonces'),
            Tab(text: 'Réservations'),
            Tab(text: 'Visites'),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildPropertiesList(),
              _buildBookingsList(),
              _buildVisitsList(),
            ],
          ),
    );
  }

  Widget _buildPropertiesList() {
    if (_myProperties.isEmpty) return _buildEmptyState('Aucune annonce publiée');
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myProperties.length,
      itemBuilder: (context, index) {
        final p = _myProperties[index];
        return FadeInUp(
          delay: Duration(milliseconds: 100 * index),
          child: Card(
            margin: const EdgeInsets.bottom(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  p.images.isNotEmpty ? p.images.first.imageUrl : '',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${NumberFormat.decimalPattern('fr').format(p.price)} F'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PropertyDetailScreen(property: p))),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingsList() {
    if (_myBookings.isEmpty) return _buildEmptyState('Aucune réservation');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myBookings.length,
      itemBuilder: (context, index) {
        final b = _myBookings[index];
        return Card(
          margin: const EdgeInsets.bottom(12),
          child: ListTile(
            title: Text('Réservation #$index'),
            subtitle: Text('Dates: ${b['start_date']} au ${b['end_date']}'),
            trailing: _buildStatusBadge(b['status']),
          ),
        );
      },
    );
  }

  Widget _buildVisitsList() {
    if (_myVisits.isEmpty) return _buildEmptyState('Aucune demande de visite');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myVisits.length,
      itemBuilder: (context, index) {
        final v = _myVisits[index];
        return Card(
          margin: const EdgeInsets.bottom(12),
          child: ListTile(
            title: Text('Visite #$index'),
            subtitle: Text('Le ${v['preferred_date']} à ${v['preferred_time']}'),
            trailing: _buildStatusBadge(v['status']),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    if (status == 'CONFIRMED' || status == 'SCHEDULED') color = Colors.green;
    if (status == 'PENDING') color = Colors.orange;
    if (status == 'CANCELLED') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
