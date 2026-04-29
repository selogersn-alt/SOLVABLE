import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../services/api_service.dart';

class BlogScreen extends StatefulWidget {
  const BlogScreen({super.key});

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.fetchBlogPosts();
      setState(() {
        _posts = list;
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
        title: const Text('Guides & Articles', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        color: const Color(0xFFDAA520),
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFDAA520)))
          : _posts.isEmpty 
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  return _buildPostCard(post, index);
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
          Icon(Icons.article_outlined, size: 80, color: Colors.blueGrey.shade100),
          const SizedBox(height: 16),
          const Text('Aucun article disponible pour le moment', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPostCard(dynamic post, int index) {
    return FadeInUp(
      delay: Duration(milliseconds: 100 * index),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => BlogPostDetailScreen(post: post))),
        child: Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  post['image'] ?? '',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, height: 180, child: const Icon(Icons.image_not_supported)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF0B4629).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                      child: const Text('IMMOBILIER', style: TextStyle(color: Color(0xFF0B4629), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    Text(post['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.3)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(post['author_name'] ?? 'Admin', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const Spacer(),
                        const Text('Lire la suite', style: TextStyle(color: Color(0xFFDAA520), fontWeight: FontWeight.bold, fontSize: 12)),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFFDAA520)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BlogPostDetailScreen extends StatelessWidget {
  final dynamic post;
  const BlogPostDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(post['image'] ?? '', fit: BoxFit.cover),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post['title'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.3)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const CircleAvatar(backgroundColor: Color(0xFF0B4629), radius: 15, child: Icon(Icons.person, size: 20, color: Colors.white)),
                      const SizedBox(width: 12),
                      Text(post['author_name'] ?? 'Admin', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text(post['created_at'].toString().split('T').first, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const Divider(height: 40),
                  Text(
                    post['content'],
                    style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
