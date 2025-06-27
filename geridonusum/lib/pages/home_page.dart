import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geridonusum/pages/weekly_detail_page.dart';
import 'package:intl/intl.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  final List<String> tips = const [
    "Plastikler doğada 1000 yıl bozulmadan kalabilir. Geri dönüştür!",
    "Geri dönüşüm, hava kirliliğini %70'e kadar azaltabilir.",
    "1 cam şişe, sonsuz kere geri dönüştürülebilir.",
    "Geri dönüşüm, enerji tasarrufu sağlar ve doğayı korur.",
    "Atıkları ayırmak, gezegen için büyük fark yaratır."
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? "Kullanıcı";
    final randomTip = tips[Random().nextInt(tips.length)];

    return Scaffold(
      backgroundColor: Colors.green[50],
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text("Merhaba $name 👋",
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Bugün çevreye katkı sağlamak için harika bir gün!",
                style: TextStyle(fontSize: 16, color: Colors.grey[700])),
            const SizedBox(height: 24),
            _scoreCard(),
            const SizedBox(height: 24),
            _sectionTitle("Geri Dönüşümün Etkisi"),
            const SizedBox(height: 12),
            _impactCard(
                "1 plastik şişe",
                "1 saatlik bilgisayar enerjisi sağlar.",
                Icons.bolt,
                Colors.orange[100]),
            const SizedBox(height: 12),
            _impactCard("1 ton kağıt", "17 ağacın kesilmesini önler.",
                Icons.forest, Colors.green[100]),
            const SizedBox(height: 24),
            _sectionTitle("Rozetlerim"),
            const SizedBox(height: 12),
            _badgeRow(),
            const SizedBox(height: 24),
            _sectionTitle("Haftalık Katkın"),
            const SizedBox(height: 12),
            _dummyChart(),
            const SizedBox(height: 24),
            _sectionTitle("Geri Dönüşüm İpucu"),
            const SizedBox(height: 8),
            _tipBox(randomTip),
            const SizedBox(height: 24),
            _youtubeSection(),
          ],
        ),
      ),
    );
  }

  Widget _scoreCard() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Text("Kullanıcı oturumu bulunamadı");
    }

    final uid = user.uid;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

    return FutureBuilder<DocumentSnapshot>(
      future: userDoc.get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        int totalPoints = 0;
        List<String> badges = [];
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          totalPoints = data['points'] ?? 0;
          badges = List<String>.from(data['badges'] ?? []);
        }

        final badgeLevel = (totalPoints ~/ 1000);
        final newBadgeName = "Rozet ${badgeLevel + 1}";
        final progress = (totalPoints % 1000) / 1000.0;

        if (!badges.contains(newBadgeName)) {
          FirebaseFirestore.instance.collection('users').doc(uid).update({
            'badges': FieldValue.arrayUnion([newBadgeName]),
          });
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.green.shade100, blurRadius: 10)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Toplam Puan", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text("$totalPoints",
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.green[100],
                color: Colors.green[700],
                minHeight: 8,
              ),
              const SizedBox(height: 4),
              Text(
                  "Yeni rozet için %${(progress * 100).toStringAsFixed(0)} tamamlandı",
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      },
    );
  }

  Widget _impactCard(
      String title, String content, IconData icon, Color? color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(icon, color: Colors.green[800]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(content, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600));
  }

  Widget _badgeRow() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Text("Rozet bilgisi alınamadı");
    }

    final uid = user.uid;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

    return FutureBuilder<DocumentSnapshot>(
      future: userDoc.get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text("Rozet verisi bulunamadı");
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final badges = List<String>.from(data['badges'] ?? []);

        if (badges.isEmpty) {
          return const Text("Henüz bir rozetin yok");
        }

        return Wrap(
          spacing: 12,
          children: badges.map((label) {
            IconData icon;
            switch (label) {
              case "İlk Adım":
                icon = Icons.emoji_flags;
                break;
              case "Yeşil Kahraman":
                icon = Icons.star;
                break;
              case "Sıfır Atık":
                icon = Icons.eco;
                break;
              case "Geri Dönüşümcü":
                icon = Icons.recycling;
                break;
              default:
                icon = Icons.verified;
            }
            return _Badge(icon: icon, label: label);
          }).toList(),
        );
      },
    );
  }

  Widget _dummyChart() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Text("Kullanıcı oturumu bulunamadı");
    }

    final uid = user.uid;
    final today = DateTime.now();
    final currentWeekday = today.weekday % 7;
    final startOfWeek =
        DateTime(today.year, today.month, today.day - currentWeekday);

    final weekDays = List.generate(7, (index) {
      final date = startOfWeek.add(Duration(days: index));
      return DateFormat('E', 'tr_TR').format(date);
    });

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("wasteHistory")
          .where("timestamp",
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        final dailyCounts = List.filled(7, 0);

        for (var doc in docs) {
          final timestamp = (doc["timestamp"] as Timestamp).toDate();
          final difference = timestamp.difference(startOfWeek).inDays;
          if (difference >= 0 && difference < 7) {
            dailyCounts[difference]++;
          }
        }

        final maxCount = dailyCounts.reduce(max);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.green.shade100, blurRadius: 6)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Haftalık Atık Grafiği",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WeeklyDetailPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Detay",
                      style: TextStyle(color: Colors.green),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (index) {
                  final value = dailyCounts[index];
                  final percentage = maxCount > 0 ? value / maxCount : 0;
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text("$value",
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Container(
                          height: (100 * percentage).toDouble(),
                          width: 20,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          weekDays[index],
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tipBox(String tip) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.yellow[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text("💡 $tip", style: const TextStyle(fontSize: 14)),
    );
  }

  Widget _youtubeSection() {
    final videoId = YoutubePlayer.convertUrlToId(
        "https://www.youtube.com/watch?v=Dn_KJ1sb0LM")!;
    YoutubePlayerController _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.play_circle_fill, color: Colors.green),
              SizedBox(width: 8),
              Text(
                "Geri Dönüşüm Hakkında Video",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: YoutubePlayer(
              controller: _controller,
              showVideoProgressIndicator: true,
              progressIndicatorColor: Colors.green,
              progressColors: const ProgressBarColors(
                playedColor: Colors.green,
                handleColor: Colors.greenAccent,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Bu kısa video, geri dönüşümün çevresel faydalarını etkileyici bir şekilde açıklıyor.",
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Badge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.green[100],
          child: Icon(icon, color: Colors.green[800]),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
