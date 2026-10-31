import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Titik awal aplikasi: menjalankan widget KatalogApp.
void main() => runApp(const KatalogApp());

// ---------- Warna & helper UI ----------
// Palet warna pastel yang dipakai di seluruh aplikasi.
const cream = Color(0xFFFFF8F1);
const pink = Color(0xFFF4DCE5);
const lavender = Color(0xFFE9E1F5);
const mint = Color(0xFFDDEDE3);
const peach = Color(0xFFFFE9D8);
const ink = Color(0xFF494454);
const muted = Color(0xFF898493);

/// Mengubah harga dolar dari API menjadi Rupiah (kurs tetap 16.000),
/// dibulatkan, lalu diberi titik ribuan. Contoh: Rp 160.000.
String money(dynamic value) {
  final hargaUSD = (value as num).toDouble();
  final hargaRupiah = (hargaUSD * 16000).round();

  final formatted = hargaRupiah.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => '.',
  );

  return 'Rp $formatted';
}

/// Helper UI: membuat TextStyle singkat (ukuran, tebal, warna).
TextStyle txt(double size, {bool bold = false, Color color = ink}) => TextStyle(
  fontSize: size,
  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
  color: color,
);

/// Helper UI: dekorasi kotak berwarna dengan sudut melengkung.
BoxDecoration box(Color c, double r) =>
    BoxDecoration(color: c, borderRadius: BorderRadius.circular(r));

/// Helper UI: gambar dari internet, ada ikon pengganti jika gagal dimuat.
Widget netImg(String? url, {double iconSize = 40}) => Image.network(
  url ?? '',
  fit: BoxFit.contain,
  errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported, size: iconSize),
);

/// Helper UI: tombol utama berwarna gelap (opsional dengan ikon).
Widget mainBtn(String label, VoidCallback onTap, {IconData? icon}) => SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: onTap,
    style: ElevatedButton.styleFrom(
      backgroundColor: ink,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.all(16),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
        Text(label),
      ],
    ),
  ),
);

/// Helper UI: tampilan kosong (ikon + teks), misal keranjang kosong.
Widget emptyState(IconData icon, String text) => Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 65, color: muted),
      const SizedBox(height: 12),
      Text(text, style: txt(14, color: muted)),
    ],
  ),
);

/// Helper UI: judul halaman (Keranjang, Pesanan).
Widget pageTitle(String t) => Padding(
  padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
  child: Align(alignment: Alignment.centerLeft, child: Text(t, style: txt(25, bold: true))),
);

/// Helper UI: label kecil berikon, dipakai untuk rating, stok, dan diskon.
Widget chip(IconData icon, String label, {Color bg = lavender, Color? iconColor}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: box(bg, 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor ?? ink),
          const SizedBox(width: 5),
          Text(label, style: txt(12, bold: true)),
        ],
      ),
    );

// ---------- App ----------
/// Widget akar: membuat MaterialApp, tema pastel, dan halaman pertama KatalogPage.
class KatalogApp extends StatelessWidget {
  const KatalogApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Delira',
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: cream,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD99EB5)),
      appBarTheme: const AppBarTheme(
        backgroundColor: cream,
        foregroundColor: ink,
        elevation: 0,
      ),
    ),
    home: const KatalogPage(),
  );
}

class KatalogPage extends StatefulWidget {
  const KatalogPage({super.key});

  @override
  State<KatalogPage> createState() => _KatalogPageState();
}

/// State halaman utama: menyimpan data produk, keranjang, pesanan, dan semua logikanya.
class _KatalogPageState extends State<KatalogPage> {
  // ---- Data yang disimpan ----
  // products: daftar produk dari API | cart: keranjang (key = id produk)
  // orders: riwayat pesanan | loading/error: status pemuatan
  // keyword: kata pencarian | selectedCategory: kategori terpilih
  // currentTab: tab aktif (0 Home, 1 Keranjang, 2 Pesanan)
  List<dynamic> products = [];
  Map<int, Map<String, dynamic>> cart = {};
  List<Map<String, dynamic>> orders = [];

  bool loading = true;
  String error = '';
  String keyword = '';
  String selectedCategory = 'Semua';
  int currentTab = 0;

  final searchController = TextEditingController();

  final pastelColors = [pink, lavender, mint, peach];

  // Jalan otomatis sekali saat halaman dibuka: langsung memuat produk dari API.
  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  // Membersihkan controller search saat halaman ditutup agar tidak boros memori.
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ---------- Logika (tidak diubah) ----------
  /// Mengambil data produk dari API dummyjson.
  /// Query kosong -> semua produk; ada query -> endpoint search.
  /// Dipakai saat halaman dibuka, saat search, dan tombol 'Coba lagi'.
  Future<void> loadProducts([String query = '']) async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      // Pilih endpoint: semua produk atau hasil pencarian (query di-encode agar aman).
      final endpoint = query.trim().isEmpty
          ? 'https://dummyjson.com/products?limit=0'
          : 'https://dummyjson.com/products/search?q=${Uri.encodeQueryComponent(query.trim())}';

      // Kirim request GET ke API, lalu cek status (harus 200).
      final response = await http.get(Uri.parse(endpoint));
      if (response.statusCode != 200) throw Exception('Gagal mengambil data');

      // Ubah teks JSON menjadi data Dart, lalu simpan daftar produknya.
      final data = jsonDecode(response.body);
      // Cegah error jika halaman sudah ditutup sebelum data tiba.
      if (!mounted) return;

      setState(() {
        products = data['products'] as List<dynamic>;
        loading = false;
        selectedCategory = 'Semua';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'Produk gagal dimuat. Periksa koneksi internet.';
      });
    }
  }

  /// Daftar kategori dari semua produk (tanpa duplikat, terurut), 'Semua' di paling depan.
  List<String> get categories {
    final values =
        products.map((p) => p['category'].toString()).toSet().toList()..sort();
    return ['Semua', ...values];
  }

  /// Produk yang ditampilkan: difilter sesuai kategori terpilih.
  List<dynamic> get visibleProducts {
    if (selectedCategory == 'Semua') return products;
    return products.where((p) => p['category'] == selectedCategory).toList();
  }

  /// Warna pastel kartu bergantian (pink, lavender, mint, peach) berdasarkan index.
  Color cardColor(int index) => pastelColors[index % pastelColors.length];

  /// Jumlah seluruh item di keranjang (untuk angka di tab Keranjang).
  int get cartCount =>
      cart.values.fold(0, (sum, item) => sum + (item['quantity'] as int));

  /// Total belanja = jumlah (harga x quantity) semua item, dalam dolar.
  double get cartTotal => cart.values.fold(
    0,
    (sum, item) =>
        sum + (item['product']['price'] as num) * (item['quantity'] as int),
  );

  /// Tambah produk ke keranjang: jika sudah ada quantity +1, jika belum buat entri baru.
  /// Lalu tampilkan SnackBar konfirmasi.
  void addToCart(dynamic product) {
    final id = product['id'] as int;
    setState(() {
      if (cart.containsKey(id)) {
        cart[id]!['quantity'] = (cart[id]!['quantity'] as int) + 1;
      } else {
        cart[id] = {'product': product, 'quantity': 1};
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Produk berhasil ditambahkan ke keranjang'),
        backgroundColor: ink,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Ubah jumlah item (+1 / -1). Jika jumlahnya 0 atau kurang, item dihapus dari keranjang.
  void changeQuantity(int id, int change) {
    setState(() {
      if (!cart.containsKey(id)) return;

      final newQuantity = (cart[id]!['quantity'] as int) + change;

      if (newQuantity <= 0) {
        cart.remove(id);
      } else {
        cart[id]!['quantity'] = newQuantity;
      }
    });
  }

  /// Buka halaman detail produk (warna latar sama dengan kartunya).
  void openDetail(dynamic product, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailPage(
          product: product,
          background: cardColor(index),
          onAdd: () => addToCart(product),
        ),
      ),
    );
  }

  /// Buka halaman checkout jika keranjang tidak kosong. Jika pembayaran dikonfirmasi,
  /// simpan ke daftar pesanan, kosongkan keranjang, lalu buka halaman sukses.
  void openCheckout() async {
    if (cart.isEmpty) return;

    final items = cart.values
        .map(
          (item) => {'product': item['product'], 'quantity': item['quantity']},
        )
        .toList();

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => CheckoutPage(items: items)),
    );

    if (result != null && mounted) {
      setState(() {
        orders.insert(0, result);
        cart.clear();
      });
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SuccessPage(order: result)),
      );
    }
  }

  // ---------- UI ----------
  /// Kerangka utama: 3 tab (Home, Keranjang, Pesanan) dengan navigasi di bawah.
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: IndexedStack(
        index: currentTab,
        children: [homePage(), cartPage(), ordersPage()],
      ),
    ),
    bottomNavigationBar: NavigationBar(
      backgroundColor: Colors.white,
      indicatorColor: pink,
      selectedIndex: currentTab,
      onDestinationSelected: (i) => setState(() => currentTab = i),
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: const Icon(Icons.shopping_bag_outlined),
          selectedIcon: const Icon(Icons.shopping_bag_rounded),
          label: 'Keranjang${cartCount > 0 ? ' ($cartCount)' : ''}',
        ),
        const NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded),
          label: 'Pesanan',
        ),
      ],
    ),
  );

  // Seluruh halaman depan bisa di-scroll (header ikut naik), jadi grid lebih lega.
  /// Halaman depan: seluruh halaman bisa di-scroll. Isinya header lalu loading / error /
  /// kosong / grid produk.
  Widget homePage() => CustomScrollView(
    slivers: [
      SliverToBoxAdapter(child: homeHeader()),
      if (loading)
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        )
      else if (error.isNotEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
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
          ),
        )
      else if (visibleProducts.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: emptyState(Icons.search_off_rounded, 'Produk tidak ditemukan.'),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.66,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) => productCard(visibleProducts[i], i),
              childCount: visibleProducts.length,
            ),
          ),
        ),
    ],
  );

  /// Header: judul toko, kolom search, banner, dan chip kategori.
  Widget homeHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('little things,', style: txt(14, color: muted)),
                  Text('Delira ✿', style: txt(28, bold: true)),
                ],
              ),
            ),
            CircleAvatar(
              backgroundColor: lavender,
              child: IconButton(
                icon: const Icon(Icons.shopping_bag_outlined, color: ink),
                onPressed: () => setState(() => currentTab = 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: searchController,
          textInputAction: TextInputAction.search,
          // Search: saat Enter ditekan, ambil data dari API sesuai kata yang diketik.
          onSubmitted: (v) {
            keyword = v;
            loadProducts(v);
          },
          decoration: InputDecoration(
            hintText: 'Cari produk favoritmu...',
            prefixIcon: const Icon(Icons.search, color: muted),
            suffixIcon: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                searchController.clear();
                keyword = '';
                loadProducts();
              },
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [pink, lavender],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('A little treat\nfor yourself ♡', style: txt(19, bold: true)),
                    const SizedBox(height: 6),
                    Text('Temukan produk pilihanmu hari ini.', style: txt(11)),
                  ],
                ),
              ),
              const Icon(Icons.card_giftcard_rounded, size: 55, color: ink),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('Kategori', style: txt(18, bold: true)),
        const SizedBox(height: 9),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: categories.map((c) {
              final selected = selectedCategory == c;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(c.replaceAll('-', ' ')),
                  selected: selected,
                  onSelected: (_) => setState(() => selectedCategory = c),
                  selectedColor: pink,
                  backgroundColor: Colors.white,
                  side: BorderSide.none,
                  labelStyle: txt(11, bold: selected),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Text('Pilihan untukmu', style: txt(19, bold: true))),
            Text('${visibleProducts.length} produk', style: txt(12, color: muted)),
          ],
        ),
      ],
    ),
  );

  // Kartu putih, gambar di atas latar pastel, badge diskon, tombol tambah.
  /// Satu kartu produk: gambar, badge diskon, judul, rating, harga, dan tombol + (tambah ke keranjang).
  /// Tap kartu untuk membuka detail.
  Widget productCard(dynamic p, int index) {
    final bg = cardColor(index);
    final discount = (p['discountPercentage'] as num?)?.round() ?? 0;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => openDetail(p, index),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: box(Colors.white, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: box(bg, 16),
                    child: Hero(tag: 'product-${p['id']}', child: netImg(p['thumbnail'])),
                  ),
                  if (discount > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: box(Colors.white, 10),
                        child: Text('-$discount%', style: txt(10, bold: true)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p['title'] ?? 'Produk',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: txt(13, bold: true),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.orange, size: 15),
                      const SizedBox(width: 2),
                      Text('${p['rating'] ?? '-'}', style: txt(11, color: muted)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(money(p['price']), style: txt(14, bold: true)),
                      ),
                      InkWell(
                        onTap: () => addToCart(p),
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: bg,
                          child: const Icon(Icons.add, size: 19, color: ink),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Halaman keranjang: daftar item, tombol +/-, total belanja, dan tombol checkout.
  Widget cartPage() => Column(
    children: [
      pageTitle('Keranjang Belanja ♡'),
      Expanded(
        child: cart.isEmpty
            ? emptyState(Icons.shopping_bag_outlined, 'Keranjangmu masih kosong.')
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: cart.entries.map((e) {
                  final p = e.value['product'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: box(Colors.white, 18),
                    child: Row(
                      children: [
                        Container(
                          width: 78,
                          height: 78,
                          padding: const EdgeInsets.all(5),
                          decoration: box(lavender, 14),
                          child: netImg(p['thumbnail']),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p['title'] ?? 'Produk',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: txt(14, bold: true),
                              ),
                              const SizedBox(height: 4),
                              Text(money(p['price']), style: txt(14, bold: true)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  qtyButton(Icons.remove, () => changeQuantity(e.key, -1)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text('${e.value['quantity']}'),
                                  ),
                                  qtyButton(Icons.add, () => changeQuantity(e.key, 1)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
      ),
      if (cart.isNotEmpty)
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: Text('Total belanja', style: txt(14, color: muted))),
                  Text(money(cartTotal), style: txt(20, bold: true)),
                ],
              ),
              const SizedBox(height: 14),
              mainBtn('Lanjut ke Checkout', openCheckout),
            ],
          ),
        ),
    ],
  );

  /// Tombol kecil +/- untuk mengubah jumlah item.
  Widget qtyButton(IconData icon, VoidCallback onTap) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(5),
      decoration: box(pink, 8),
      child: Icon(icon, size: 16, color: ink),
    ),
  );

  /// Halaman riwayat pesanan dari daftar orders.
  Widget ordersPage() => Column(
    children: [
      pageTitle('Pesanan Saya'),
      Expanded(
        child: orders.isEmpty
            ? emptyState(Icons.receipt_long_outlined, 'Belum ada pesanan.')
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: orders
                    .map(
                      (o) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: box(Colors.white, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green),
                                const SizedBox(width: 8),
                                Text('Pesanan berhasil dibuat', style: txt(14, bold: true)),
                              ],
                            ),
                            const SizedBox(height: 9),
                            Text('Metode: ${o['method']}'),
                            const SizedBox(height: 5),
                            Text('Total: ${money(o['total'])}'),
                            const SizedBox(height: 5),
                            Text('Status: Simulasi berhasil', style: txt(14, color: Colors.green)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
      ),
    ],
  );
}

// ---------- Halaman Detail ----------
/// Halaman detail produk: memakai data produk yang dikirim dari halaman depan (tanpa panggil API lagi).
class DetailPage extends StatefulWidget {
  final dynamic product;
  final Color background;
  final VoidCallback onAdd;

  const DetailPage({
    super.key,
    required this.product,
    required this.background,
    required this.onAdd,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  // Index gambar yang sedang tampil di galeri (berubah saat thumbnail di-tap).
  int selected = 0;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final images = ((p['images'] as List?) ?? []).cast<String>();
    if (images.isEmpty) images.add(p['thumbnail'] ?? '');
    final discount = (p['discountPercentage'] as num?)?.round() ?? 0;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Area gambar pastel dengan galeri thumbnail
          Container(
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 16),
            decoration: BoxDecoration(
              color: widget.background,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: ink),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                SizedBox(
                  height: 270,
                  child: Hero(
                    tag: 'product-${p['id']}',
                    child: netImg(images[selected], iconSize: 60),
                  ),
                ),
                if (images.length > 1) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 56,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      itemCount: images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => setState(() => selected = i),
                        child: Container(
                          width: 56,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: i == selected ? ink : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: netImg(images[i], iconSize: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Informasi produk
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (p['category'] ?? '').toString().replaceAll('-', ' ').toUpperCase(),
                  style: txt(12, bold: true, color: muted),
                ),
                const SizedBox(height: 6),
                Text(p['title'] ?? 'Produk', style: txt(25, bold: true)),
                if (p['brand'] != null) ...[
                  const SizedBox(height: 4),
                  Text('oleh ${p['brand']}', style: txt(13, color: muted)),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    chip(Icons.star_rounded, '${p['rating'] ?? '-'}', bg: peach, iconColor: Colors.orange),
                    chip(Icons.inventory_2_outlined, 'Stok ${p['stock'] ?? '-'}', bg: mint),
                    if (discount > 0) chip(Icons.local_offer_outlined, 'Diskon $discount%', bg: pink),
                  ],
                ),
                const SizedBox(height: 22),
                Text('Deskripsi Produk', style: txt(18, bold: true)),
                const SizedBox(height: 8),
                Text(
                  p['description'] ?? 'Tidak ada deskripsi.',
                  style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
                ),
                const SizedBox(height: 20),
                for (final info in [
                  [Icons.local_shipping_outlined, p['shippingInformation']],
                  [Icons.verified_outlined, p['warrantyInformation']],
                ])
                  if (info[1] != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(13),
                      decoration: box(Colors.white, 14),
                      child: Row(
                        children: [
                          Icon(info[0] as IconData, color: ink, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text('${info[1]}', style: txt(13))),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
      // Bar harga + tombol selalu terlihat di bawah
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Harga', style: txt(12, color: muted)),
                  Text(money(p['price']), style: txt(20, bold: true)),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: mainBtn('Tambah ke Keranjang', widget.onAdd, icon: Icons.shopping_bag_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Checkout & Sukses ----------
/// Halaman checkout: ringkasan pesanan, pilih metode pembayaran, konfirmasi (simulasi).
class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  const CheckoutPage({super.key, required this.items});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // Metode pembayaran yang dipilih (default QRIS).
  String method = 'QRIS (Simulasi)';

  /// Total pembayaran dari seluruh item yang dibeli.
  double get total => widget.items.fold(
    0,
    (sum, item) =>
        sum + (item['product']['price'] as num) * (item['quantity'] as int),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Ringkasan Pesanan', style: txt(20, bold: true)),
          const SizedBox(height: 12),
          ...widget.items.map(
            (i) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(13),
              decoration: box(Colors.white, 16),
              child: Row(
                children: [
                  Expanded(child: Text('${i['product']['title']} × ${i['quantity']}', style: txt(14))),
                  Text(
                    money((i['product']['price'] as num) * (i['quantity'] as int)),
                    style: txt(14, bold: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Metode Pembayaran', style: txt(20, bold: true)),
          const SizedBox(height: 10),
          paymentOption('QRIS (Simulasi)', Icons.qr_code_2),
          paymentOption('Transfer Bank (Simulasi)', Icons.account_balance),
          paymentOption('E-Wallet (Simulasi)', Icons.account_balance_wallet),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: box(lavender, 18),
            child: Row(
              children: [
                Expanded(child: Text('Total Pembayaran', style: txt(14, bold: true))),
                Text(money(total), style: txt(20, bold: true)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '* Ini merupakan simulasi pembayaran. Tidak ada uang sungguhan yang diproses.',
            style: txt(11, color: muted),
          ),
          const SizedBox(height: 18),
          mainBtn(
            'Konfirmasi Pembayaran',
            // Konfirmasi: kembali ke halaman sebelumnya sambil mengirim data pesanan ke openCheckout.
            () => Navigator.pop(context, {
              'method': method,
              'total': total,
              'items': widget.items,
              'date': DateTime.now().toString(),
            }),
          ),
        ],
      ),
    );
  }

  /// Satu pilihan metode pembayaran (radio button).
  Widget paymentOption(String value, IconData icon) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    decoration: box(Colors.white, 15),
    child: RadioListTile<String>(
      value: value,
      groupValue: method,
      activeColor: ink,
      onChanged: (v) => setState(() => method = v ?? method),
      secondary: Icon(icon, color: ink),
      title: Text(value, style: txt(13, bold: true)),
    ),
  );
}

/// Halaman konfirmasi pesanan berhasil.
class SuccessPage extends StatelessWidget {
  final Map<String, dynamic> order;
  const SuccessPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 48,
              backgroundColor: mint,
              child: Icon(Icons.check_rounded, size: 55, color: Color(0xFF4C8B69)),
            ),
            const SizedBox(height: 24),
            Text('Yeay! Pesanan Berhasil ♡', textAlign: TextAlign.center, style: txt(23, bold: true)),
            const SizedBox(height: 12),
            Text('Terima kasih sudah berbelanja di Delira.', style: txt(14, color: muted)),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: box(Colors.white, 20),
              child: Column(
                children: [
                  Text('Metode: ${order['method']}'),
                  const SizedBox(height: 8),
                  Text('Total: ${money(order['total'])}', style: txt(14, bold: true)),
                  const SizedBox(height: 8),
                  Text('Status: Simulasi berhasil', style: txt(14, color: Colors.green)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            mainBtn('Kembali ke Beranda', () => Navigator.pop(context)),
          ],
        ),
      ),
    ),
  );
}
