import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../student/mentor_review_screen.dart';

class MentorProfileScreen extends StatefulWidget {
  final Map<String, dynamic> mentor;
  const MentorProfileScreen({super.key, required this.mentor});

  @override
  State<MentorProfileScreen> createState() => _MentorProfileScreenState();
}

class _MentorProfileScreenState extends State<MentorProfileScreen> {
  List<dynamic> _reviews = [];
  bool _isLoadingReviews = true;
  double _avgRating = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    final mId = widget.mentor['uid'].toString();
    if (mounted) setState(() => _isLoadingReviews = true);
    
    try {
      final data = await ApiService.getMentorReviews(mId);
      if (mounted) {
        setState(() {
          _reviews = data;
          if (_reviews.isNotEmpty) {
            double total = 0;
            for (var r in _reviews) {
              total += double.tryParse(r['rating'].toString()) ?? 0.0;
            }
            _avgRating = total / _reviews.length;
          }
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  Future<void> _launchURL(String? url) async {
    if (url == null || url.isEmpty || url == 'null') return;
    final Uri uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("URL ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final String skillsStr = widget.mentor['skills'] ?? '';
    final List<String> skillsList = skillsStr.split(',').where((s) => s.trim().isNotEmpty).toList();
    
    // Safety check to avoid double "Years" if data already contains it
    String experience = widget.mentor['experience'] ?? 'N/A';
    if (experience.toLowerCase().contains('year')) {
      // Keep as is if already has "Years"
    } else if (experience != 'N/A') {
      experience = "$experience Years";
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.white24,
                      child: Text(widget.mentor['name']?[0] ?? 'M', style: const TextStyle(fontSize: 35, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 10),
                    Text(widget.mentor['name'] ?? 'Mentor', style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                      child: Text('Exp: $experience', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRatingHeader(),
                  const SizedBox(height: 25),
                  
                  _sectionHeader('Expertise'),
                  skillsList.isEmpty 
                    ? _infoCard('No specific skills listed.')
                    : Wrap(
                        spacing: 10, runSpacing: 10,
                        children: skillsList.map((skill) => Chip(
                          label: Text(skill.trim(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6A11CB))),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: const Color(0xFF6A11CB).withOpacity(0.1)),
                        )).toList(),
                      ),
                  
                  const SizedBox(height: 25),
                  _sectionHeader('Bio'),
                  _infoCard(widget.mentor['bio'] ?? 'Experienced academic mentor.'),
                  
                  const SizedBox(height: 25),
                  _sectionHeader('Social Connect'),
                  _buildSocialRow(),
                  
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionHeader('Reviews'),
                      TextButton.icon(
                        onPressed: () async {
                          final res = await Navigator.push(context, MaterialPageRoute(builder: (context) => MentorReviewScreen(mentor: widget.mentor)));
                          if (res == true) _fetchReviews();
                        },
                        icon: const Icon(Icons.rate_review_outlined, size: 16),
                        label: const Text('Write Review', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6A11CB), fontSize: 12)),
                      )
                    ],
                  ),
                  _isLoadingReviews 
                    ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF6A11CB))))
                    : _reviews.isEmpty
                      ? const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('No reviews yet.', style: TextStyle(color: Colors.grey, fontSize: 13))))
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _reviews.length,
                          itemBuilder: (context, index) => _reviewCard(_reviews[index]),
                        ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRatingHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(children: [Text(_avgRating.toStringAsFixed(1), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.amber)), const Text('AVG RATING', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold))]),
          Container(width: 1, height: 40, color: Colors.grey[100]),
          Column(children: [Text(_reviews.length.toString(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF6A11CB))), const Text('REVIEWS', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold))]),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.2)));
  }

  Widget _infoCard(String text) {
    return Container(
      padding: const EdgeInsets.all(18), width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[100]!)),
      child: Text(text, style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.6)),
    );
  }

  Widget _buildSocialRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _socialBtn(Icons.link, 'LinkedIn', widget.mentor['linkedin_url'] ?? widget.mentor['linkedin']),
        _socialBtn(Icons.code, 'GitHub', widget.mentor['github_url'] ?? widget.mentor['github']),
        _socialBtn(Icons.language, 'Web', widget.mentor['portfolio_url'] ?? widget.mentor['portfolio']),
      ],
    );
  }

  Widget _socialBtn(IconData icon, String label, String? url) {
    bool hasUrl = url != null && url.isNotEmpty && url != 'null';
    return InkWell(
      onTap: () => _launchURL(url),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: hasUrl ? const Color(0xFF6A11CB).withOpacity(0.1) : Colors.grey[50]!)),
        child: Column(children: [Icon(icon, color: hasUrl ? const Color(0xFF6A11CB) : Colors.grey[300], size: 20), const SizedBox(height: 5), Text(label, style: TextStyle(fontSize: 9, color: hasUrl ? Colors.black87 : Colors.grey[300], fontWeight: FontWeight.bold))]),
      ),
    );
  }

  Widget _reviewCard(Map<String, dynamic> r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(r['student_name'] ?? 'Learner', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Row(children: List.generate(5, (i) => Icon(Icons.star_rounded, size: 16, color: i < (int.tryParse(r['rating'].toString()) ?? 0) ? Colors.amber : Colors.grey[100]))),
            ],
          ),
          const SizedBox(height: 8),
          Text(r['review_text'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.4)),
        ],
      ),
    );
  }
}