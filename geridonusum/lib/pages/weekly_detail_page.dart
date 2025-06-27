import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class WeeklyDetailPage extends StatefulWidget {
  const WeeklyDetailPage({super.key});

  @override
  State<WeeklyDetailPage> createState() => _WeeklyDetailPageState();
}

class _WeeklyDetailPageState extends State<WeeklyDetailPage> {
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final weekday = now.weekday;
    _startDate = now.subtract(Duration(days: weekday - 1));
    _endDate = _startDate.add(const Duration(days: 7));
    _endDate =
        DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Kullanıcı oturumu bulunamadı")),
      );
    }

    final uid = user.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text("Haftalık Atık Detayı"),
        backgroundColor: Colors.green[600],
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _startDate,
                firstDate: DateTime(2023),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() {
                  final weekday = picked.weekday;
                  _startDate = picked.subtract(Duration(days: weekday - 1));
                  _endDate = _startDate.add(const Duration(days: 7));
                  _endDate = DateTime(
                      _endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
                });
              }
            },
          )
        ],
      ),
      backgroundColor: Colors.green[50],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .collection("wasteHistory")
              .where("timestamp",
                  isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
              .where("timestamp", isLessThan: Timestamp.fromDate(_endDate))
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const Center(child: Text("Bu hafta henüz katkı yok."));
            }

            final totalPoints = docs.fold<int>(
                0, (sum, doc) => sum + ((doc['points'] ?? 0) as num).toInt());
            final Map<String, int> dailyPoints = {};
            final Map<String, int> typeCounts = {};

            for (var doc in docs) {
              final type = doc['type'] ?? 'Bilinmiyor';
              final timestamp = (doc['timestamp'] as Timestamp).toDate();
              final day = DateFormat('EEE', 'tr_TR').format(timestamp);
              final point = ((doc['points'] ?? 0) as num).toInt();

              dailyPoints[day] = (dailyPoints[day] ?? 0) + point;
              typeCounts[type] = (typeCounts[type] ?? 0) + point;
            }

            return ListView(
              children: [
                _buildSummaryCard(totalPoints),
                const SizedBox(height: 16),
                _buildPieChart(typeCounts),
                const SizedBox(height: 16),
                _buildBarChart(dailyPoints),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(int totalPoints) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.green.shade100, blurRadius: 10)],
      ),
      child: Row(
        children: [
          const Icon(Icons.eco, color: Colors.green, size: 36),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Toplam Puan",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text("$totalPoints puan",
                  style: const TextStyle(fontSize: 22, color: Colors.green)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPieChart(Map<String, int> data) {
    final total = data.values.fold(0, (sum, val) => sum + val);
    final entries = data.entries.toList();
    final colors = [
      Colors.green[300],
      Colors.green[500],
      Colors.green[700],
      Colors.green[900],
      Colors.teal[400]
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Atık Türü Dağılımı",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: Row(
            children: entries.mapIndexed((i, entry) {
              final percent = (entry.value / total * 100).toStringAsFixed(1);
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                        radius: 8, backgroundColor: colors[i % colors.length]),
                    const SizedBox(height: 6),
                    Text(entry.key, style: const TextStyle(fontSize: 12)),
                    Text("$percent%",
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }).toList(),
          ),
        )
      ],
    );
  }

  Widget _buildBarChart(Map<String, int> data) {
    final maxVal = data.values.isEmpty ? 1 : data.values.reduce(max);
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Günlük Katkı Dağılımı",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...sortedEntries.map((entry) {
          final percentage = entry.value / maxVal;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(width: 60, child: Text(entry.key)),
                Expanded(
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Colors.green[100],
                    color: Colors.green[600],
                    minHeight: 10,
                  ),
                ),
                const SizedBox(width: 8),
                Text("${entry.value}p"),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}

extension on List {
  Iterable<T> mapIndexed<T>(T Function(int, dynamic) f) sync* {
    for (int i = 0; i < length; i++) {
      yield f(i, this[i]);
    }
  }
}
