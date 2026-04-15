import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/property_model.dart';

class PropertyDetailScreen extends StatelessWidget {
  final Property property;

  const PropertyDetailScreen({super.key, required this.property});

  void _launchWhatsApp() async {
    final String message = "Bonjour, je suis intéressé par votre annonce : ${property.title}. L'offre est-elle toujours disponible ?";
    final String url = "https://wa.me/${property.owner.phoneNumber}?text=${Uri.encodeComponent(message)}";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _launchCall() async {
    final String url = "tel:${property.owner.phoneNumber}";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar avec Image Parallaxe
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: const Color(0xFF0B4629),
            flexibleSpace: FlexibleSpaceBar(
              background: property.images.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          property.images.first.imageUrl,
                          fit: BoxFit.cover,
                        ),
                        // Overlay progressif pour la lisibilité
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.black26, Colors.transparent, Colors.black26],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(color: Colors.grey[200]),
            ),
          ),

          // Contenu de la page
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type et Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B4629).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          property.listingCategoryDisplay,
                          style: const TextStyle(color: Color(0xFF0B4629), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      if (property.isBoosted)
                        const Row(
                          children: [
                            Icon(Icons.bolt, color: Colors.amber, size: 20),
                            Text('Annonce Premium', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Titre
                  Text(
                    property.title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Localisation
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 5),
                      Text(
                        '${property.neighborhood}, ${property.city}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // Prix
                  Text(
                    currencyFormatter.format(property.price),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0B4629)),
                  ),
                  const SizedBox(height: 25),

                  // Caractéristiques (Lits, Bains, Surface)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFeature(Icons.bed, '${property.bedrooms} Ch'),
                      _buildFeature(Icons.bathtub, '${property.bathrooms} SdB'),
                      _buildFeature(Icons.square_foot, '${property.surface.toInt()} m²'),
                      _buildFeature(Icons.home, property.propertyTypeDisplay),
                    ],
                  ),
                  
                  const Divider(height: 50),

                  // Description
                  const Text('Description', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                    property.description,
                    style: TextStyle(fontSize: 16, color: Colors.grey[800], height: 1.5),
                  ),

                  const SizedBox(height: 40),

                  // Propriétaire (Card)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                                backgroundColor: Color(0xFF0B4629),
                                child: Icon(Icons.person, color: Colors.white)),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    property.owner.displayName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                  const Text('Professionnel vérifié Loger SN', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _launchWhatsApp,
                                icon: const Icon(Icons.message, color: Colors.white),
                                label: const Text('WhatsApp', style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF25D366),
                                    padding: const EdgeInsets.symmetric(vertical: 12)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _launchCall,
                                icon: const Icon(Icons.phone, color: Colors.white),
                                label: const Text('Appeler', style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0B4629),
                                    padding: const EdgeInsets.symmetric(vertical: 12)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100), // Espace pour pas être gêné par le bas
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[700], size: 28),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
