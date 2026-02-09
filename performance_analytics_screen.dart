import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class PerformanceAnalyticsScreen extends StatefulWidget {
  final String mentorId;
  const PerformanceAnalyticsScreen({super.key, required this.mentorId});

  @override
  State<PerformanceAnalyticsScreen> createState() => _PerformanceAnalyticsScreenState();
}

class _PerformanceAnalyticsScreenState extends State<PerformanceAnalyticsScreen> {
  List<dynamic> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final auth = Provider.of<MyAuthProvider>(context, listen: false);
    if (auth.user == null) return;
    
    try {
      final data = await ApiService.getQuizHistory(auth.user!.uid);
      if (mounted) {
        setState(() {
          // Robust filtering for specific mentor
          _history = data.where((q) {
            return q['mentor_id'].toString() == widget.mentorId.toString();
          }).toList().reversed.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('Growth Analytics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]))),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A11CB)))
          : _history.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 25),
                      _buildChartCard(),
                      const SizedBox(height: 30),
                      const Text('PERFORMANCE LOG', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.2)),
                      const SizedBox(height: 15),
                      ..._history.reversed.map((res) => _buildMiniStat(res)).toList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    double avg = 0;
    if (_history.isNotEmpty) {
      double totalPerc = 0;
      for (var item in _history) {
        double s = double.tryParse(item['score'].toString()) ?? 0;
        double t = double.tryParse(item['total_questions'].toString()) ?? 1;
        totalPerc += (s / t) * 100;
      }
      avg = totalPerc / _history.length;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('Quizzes', _history.length.toString()),
          _statItem('Avg Accuracy', '${avg.toInt()}%'),
          _statItem('Efficiency', avg >= 70 ? 'High' : (avg >= 40 ? 'Avg' : 'Low')),
        ],
      ),
    );
  }

  Widget _statItem(String label, String val) {
    return Column(children: [Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6A11CB))), Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold))]);
  }

  Widget _buildChartCard() {
    return Container(
      height: 280, width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 25, 25, 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)]),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey[100]!, strokeWidth: 1)),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, meta) {
              if (val.toInt() >= 0 && val.toInt() < _history.length) {
                return Padding(padding: const EdgeInsets.only(top: 8), child: Text('Q${val.toInt() + 1}', style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)));
              }
              return const Text('');
            })),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _history.asMap().entries.map((e) {
                double s = double.tryParse(e.value['score'].toString()) ?? 0;
                double t = double.tryParse(e.value['total_questions'].toString()) ?? 1;
                return FlSpot(e.key.toDouble(), (s / t) * 100);
              }).toList(),
              isCurved: true, color: const Color(0xFF6A11CB), barWidth: 3, dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: const Color(0xFF6A11CB).withOpacity(0.05)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(Map<String, dynamic> res) {
    double s = double.tryParse(res['score'].toString()) ?? 0;
    double t = double.tryParse(res['total_questions'].toString()) ?? 1;
    double perc = (s / t) * 100;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[100]!)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(res['title'] ?? 'Quiz', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: perc >= 50 ? Colors.green[50] : Colors.red[50], borderRadius: BorderRadius.circular(8)),
            child: Text('${s.toInt()} / ${t.toInt()}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: perc >= 50 ? Colors.green : Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.analytics_outlined, size: 80, color: Colors.grey), SizedBox(height: 15), Text('No analytics data yet.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))]));
  }
}