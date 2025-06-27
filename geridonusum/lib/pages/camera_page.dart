import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final List<Map<String, dynamic>> history = [];
  bool isLoading = false;
  int countdownSeconds = 0;

  @override
  void initState() {
    super.initState();
    loadWasteHistory();
  }

  Future<void> startCountdown(int seconds) async {
    countdownSeconds = seconds;
    while (countdownSeconds > 0) {
      setState(() {});
      await Future.delayed(const Duration(seconds: 1));
      countdownSeconds--;
    }
    setState(() {});
  }

  Future<void> pickAndAnalyzeImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    final imageBytes = await pickedFile.readAsBytes();

    setState(() => isLoading = true);

    await startCountdown(5); // Countdown starts here

    final fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
    final storageRef = FirebaseStorage.instance.ref().child(
        "waste_images/${FirebaseAuth.instance.currentUser!.uid}/$fileName");

    await storageRef.putData(
        imageBytes, SettableMetadata(contentType: 'image/jpeg'));
    final imageUrl = await storageRef.getDownloadURL();

    final category = await analyzeWithGemini(imageBytes);
    if (category != null) {
      final points = getPointsForCategory(category);
      final timestamp = DateTime.now();

      final userId = FirebaseAuth.instance.currentUser!.uid;
      final userDoc =
          FirebaseFirestore.instance.collection("users").doc(userId);

      await userDoc.update({
        "points": FieldValue.increment(points),
        "wasteCount": FieldValue.increment(1),
      });

      await userDoc.collection("wasteHistory").add({
        "type": category,
        "points": points,
        "timestamp": Timestamp.now(),
        "imageUrl": imageUrl,
      });

      setState(() {
        history.insert(0, {
          'type': category,
          'points': points,
          'timestamp': timestamp,
          'imageUrl': imageUrl,
        });
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> loadWasteHistory() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("wasteHistory")
        .orderBy("timestamp", descending: true)
        .get();

    setState(() {
      history.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        history.add({
          "type": data["type"],
          "points": data["points"],
          "timestamp": (data["timestamp"] as Timestamp).toDate(),
          "imageUrl": data["imageUrl"],
        });
      }
    });
  }

  Future<String?> analyzeWithGemini(Uint8List imageBytes) async {
    const apiKey = "-";
    final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$apiKey");

    final base64Image = base64Encode(imageBytes);

    final body = {
      "contents": [
        {
          "parts": [
            {
              "text":
                  "Bu görselde hangi tür atık var? Sadece şu kategorilerden birini yaz: plastik, kağıt, cam, metal, organik, elektronik, tehlikeli, diğer."
            },
            {
              "inlineData": {
                "mimeType": "image/jpeg",
                "data": base64Image,
              }
            }
          ]
        }
      ]
    };

    final response = await http.post(url,
        headers: {"Content-Type": "application/json"}, body: jsonEncode(body));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final text = decoded['candidates'][0]['content']['parts'][0]['text'];
      return text.trim().toLowerCase();
    } else {
      print("Gemini Error: ${response.body}");
      return null;
    }
  }

  int getPointsForCategory(String category) {
    const pointsMap = {
      "plastik": 10,
      "kağıt": 8,
      "cam": 6,
      "metal": 12,
      "organik": 4,
      "elektronik": 15,
      "tehlikeli": 20,
      "diğer": 2,
    };
    return pointsMap[category] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: const Text("Çöp Takibi"),
        backgroundColor: Colors.green[400],
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.camera_alt, color: Colors.green),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Çöp eklemek için kamera aç",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(
                      Icons.add_a_photo,
                      size: 20,
                      color: Colors.white,
                    ),
                    label: Text(
                      "Ekle",
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: isLoading ? null : pickAndAnalyzeImage,
                  )
                ],
              ),
            ),
          ),
          if (isLoading && countdownSeconds > 0)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "$countdownSeconds saniye içinde analiz başlıyor...",
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: const [
                Icon(Icons.history, color: Colors.green),
                SizedBox(width: 8),
                Text("Çöp Geçmişin",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final data = history[index];
                final formattedDate = DateFormat('dd MMM yyyy, HH:mm', 'tr_TR')
                    .format(data['timestamp'] as DateTime);

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WasteDetailPage(data: data),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.green.shade100, blurRadius: 6)
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.green[100],
                          child: Icon(
                            _getIconForType(data['type'] as String),
                            color: Colors.green[800],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['type'] as String,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(formattedDate,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Text("+${data['points']} puan",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'plastik':
        return Icons.local_drink;
      case 'kağıt':
        return Icons.description;
      case 'cam':
        return Icons.wine_bar;
      case 'metal':
        return Icons.build;
      case 'organik':
        return Icons.eco;
      case 'elektronik':
        return Icons.memory;
      case 'tehlikeli':
        return Icons.warning;
      default:
        return Icons.recycling;
    }
  }
}

class WasteDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const WasteDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm', 'tr_TR')
        .format(data['timestamp'] as DateTime);

    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: const Text("Atık Detayı"),
        backgroundColor: Colors.green[400],
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.green.shade100, blurRadius: 6)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data["imageUrl"] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    data["imageUrl"],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.category, color: Colors.green[800]),
                  const SizedBox(width: 8),
                  Text("Tür: ${data["type"]}",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.green[800]),
                  const SizedBox(width: 8),
                  Text("Puan: +${data["points"]} puan",
                      style: const TextStyle(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.green[800]),
                  const SizedBox(width: 8),
                  Text("Zaman: $formattedDate",
                      style: const TextStyle(fontSize: 16)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
