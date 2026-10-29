
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const KatalogApp());
}

const cream = Color(0xFFFFF8EF);
const pink = Color(0xFFF5DCE5);
const lavender = Color(0xFFE5DFF5);
const mint = Color(0xFFDDEDE3);
const ink = Color(0xFF494454);

class KatalogApp extends StatelessWidget {
  const KatalogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pastel Product',
      theme: ThemeData(
        scaffoldBackgroundColor: cream,
        colorScheme: ColorScheme.fromSeed(seedColor: pink),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: cream,
          foregroundColor: ink,
          elevation: 0,
        ),
      ),
      home: const KatalogPage(),
    );
  }
}

class KatalogPage extends StatefulWidget {
  const KatalogPage({super.key});

  @override
  State<KatalogPage> createState() => _KatalogPageState();
}

class _KatalogPageState extends State<KatalogPage> {
  List<dynamic> products = [];
  bool loading = true;
  String error = '';
  String keyword = '';

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts([String query = '']) async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final endpoint = query.trim().isEmpty
          ? 'https://dummyjson.com/products?limit=0'
          : 'https://dummyjson.com/products/search?q=${Uri.encodeQueryComponent(query.trim())}';

      final response = await http.get(Uri.parse(endpoint));

      if (response.statusCode != 200) {
        throw Exception('Gagal mengambil data produk.');
      }

      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        products = data['products'] as List<dynamic>;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = 'Data gagal dimuat. Periksa internet lalu coba lagi.';
      });
    }
  }

  Color cardColor(int index) {
    const colors = [pink, lavender, mint, Color(0xFFF8EACB)];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'little things,',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.brown,
                    ),
                  ),
                  const Text(
                    'Lovely Finds ✿',
                    style: TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.bold,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Temukan produk favoritmu.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    onChanged: (value) {
                      keyword = value;
                      loadProducts(value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari nama produk...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Semua Produk',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: ink,
                          ),
                        ),
                      ),
                      Text(
                        '${products.length} produk',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : error.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(error),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => loadProducts(keyword),
                                child: const Text('Coba lagi'),
                              ),
                            ],
                          ),
                        )
                      : products.isEmpty
                          ? const Center(
                              child: Text('Produk tidak ditemukan.'),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                16, 4, 16, 20,
                              ),
                              itemCount: products.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.61,
                              ),
                              itemBuilder: (context, index) {
                                final product = products[index];

                                return InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DetailPage(
                                          product: product,
                                          background: cardColor(index),
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: cardColor(index),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Center(
                                            child: Image.network(
                                              product['thumbnail'] ?? '',
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                Icons.image_not_supported,
                                                size: 45,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          product['title'] ?? 'Produk',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: ink,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '\$${product['price']}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: ink,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star_rounded,
                                              size: 17,
                                              color: Colors.orange,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              '${product['rating'] ?? '-'}',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  final dynamic product;
  final Color background;

  const DetailPage({
    super.key,
    required this.product,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Produk'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 290,
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Image.network(
                product['thumbnail'] ?? '',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image_not_supported, size: 60),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              product['category'] ?? 'Kategori',
              style: const TextStyle(color: Colors.brown),
            ),
            const SizedBox(height: 8),
            Text(
              product['title'] ?? 'Produk',
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: ink,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '\$${product['price']}',
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: ink,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.orange),
                const SizedBox(width: 5),
                Text('${product['rating'] ?? '-'}'),
                const SizedBox(width: 14),
                Text('Stok: ${product['stock'] ?? '-'}'),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Deskripsi Produk',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product['description'] ?? 'Tidak ada deskripsi.',
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
