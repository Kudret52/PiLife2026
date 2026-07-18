import 'package:flutter/material.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> news = [
      {
        "title": "PiLife Güncellemesi",
        "content": "Notlar ve görevler artık bulut üzerinde saklanabiliyor.",
      },
      {
        "title": "Pi Pazar Aktif",
        "content": "Pi kullanıcıları artık ürün alıp satabiliyor.",
      },
      {
        "title": "Profil Sistemi Yenilendi",
        "content": "Profil ekranı yeni tasarıma geçirildi.",
      },
      {
        "title": "Yeni Tema",
        "content": "Pi Network renkleri uygulamaya eklendi.",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FC),

      appBar: AppBar(
        backgroundColor: const Color(0xFF5B2D90),
        foregroundColor: Colors.white,
        title: const Text("PiLife Haberler"),
        centerTitle: true,
      ),

      body: ListView.builder(
        itemCount: news.length,
        itemBuilder: (context, index) {
          return Card(
            color: Colors.white,
            elevation: 4,
            margin: const EdgeInsets.all(12),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),

            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF4AF2C),
                child: Icon(Icons.newspaper, color: Color(0xFF5B2D90)),
              ),

              title: Text(
                news[index]["title"]!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),

              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(news[index]["content"]!),
              ),
            ),
          );
        },
      ),
    );
  }
}
