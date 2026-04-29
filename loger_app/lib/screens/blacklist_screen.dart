import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../services/api_service.dart';

class BlacklistScreen extends StatefulWidget {
  const BlacklistScreen({super.key});

  @override
  State<BlacklistScreen> createState() => _BlacklistScreenState();
}

class _BlacklistScreenState extends State<BlacklistScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.fetchBlacklist();
      setState(() {
        _reports = list;
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
        title: const Text('Liste Noire Sécurisée', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadReports,
        color: const Color(0xFFDAA520),
        child: Column(
          children: [
            _buildSecurityHeader(),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFDAA520)))
                : _reports.isEmpty 
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _reports.length,
                      itemBuilder: (context, index) {
                        final report = _reports[index];
                        return _buildReportCard(report, index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0B4629),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF0B4629).withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          const Icon(Icons.security, color: Color(0xFFDAA520), size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Protection Loger Sénégal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 4),
                Text('Consultez les signalements validés pour éviter les arnaques.', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_outlined, size: 80, color: Colors.green.shade100),
          const SizedBox(height: 16),
          const Text('Aucun signalement critique actuellement.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildReportCard(dynamic report, int index) {
    bool isCritical = report['is_critical_alert'] ?? false;
    
    return FadeInUp(
      delay: Duration(milliseconds: 100 * index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isCritical ? Colors.red.shade100 : Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCritical ? Colors.red.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isCritical ? 'CRITIQUE' : 'SIGNALEMENT',
                      style: TextStyle(color: isCritical ? Colors.red : Colors.orange.shade700, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  Text(report['created_at'].toString().split('T').first, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 12),
              Text(report['reported_pro_name'] ?? 'Inconnu', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(report['reported_pro_phone'] ?? 'Non communiqué', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              const Divider(height: 24),
              const Text('Motif du signalement :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey)),
              const SizedBox(height: 4),
              Text(report['fraud_description'] ?? 'Aucun détail fourni.', style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }
}
