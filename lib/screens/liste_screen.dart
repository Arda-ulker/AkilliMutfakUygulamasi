import 'package:flutter/material.dart';
import 'package:akilli_mutfak/constants/app_colors.dart';
import 'package:akilli_mutfak/models/shopping_item.dart';
import 'package:akilli_mutfak/screens/alisveris_gorunum_screen.dart';
import 'package:akilli_mutfak/screens/tum_urunler_screen.dart';

class ListeScreen extends StatefulWidget {
  const ListeScreen({super.key});

  @override
  State<ListeScreen> createState() => _ListeScreenState();
}

class _ListeScreenState extends State<ListeScreen> {
  final List<ShoppingItem> _items = [];
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  String _inputText = '';

  static const _suggestions = [
    ('🥛', '2L Süt'),
    ('🍞', 'Ekmek'),
    ('🥚', 'Yumurta'),
    ('🧀', 'Kaşar Peyniri'),
    ('🍅', 'Domates'),
    ('🧅', 'Soğan'),
  ];

  @override
  void initState() {
    super.initState();
    _inputController.addListener(
      () => setState(() => _inputText = _inputController.text.trim()),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _addItem() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    setState(() => _items.insert(0, ShoppingItem(name: text)));
    _inputController.clear();
    _inputFocus.requestFocus();
  }

  void _toggleItem(ShoppingItem item) {
    setState(() => item.isChecked = !item.isChecked);
  }

  void _removeItem(ShoppingItem item) {
    final index = _items.indexOf(item);
    setState(() => _items.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${item.name}" listeden kaldırıldı'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Geri Al',
          textColor: kGreen,
          onPressed: () => setState(() => _items.insert(index, item)),
        ),
      ),
    );
  }

  List<ShoppingItem> get _unchecked =>
      _items.where((i) => !i.isChecked).toList();
  List<ShoppingItem> get _checked =>
      _items.where((i) => i.isChecked).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 14),
            _buildInputField(),
            const SizedBox(height: 8),
            Expanded(
              child: _items.isEmpty
                  ? _buildEmptyState()
                  : _buildItemList(),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final checked = _checked.length;
    final total = _items.length;
    return Container(
      color: kBg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: kGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shopping_cart_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Alışveriş Listem',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                Text(
                  total == 0
                      ? 'Ürün ekleyerek başla'
                      : '$checked / $total ürün sepete alındı',
                  style: const TextStyle(fontSize: 12, color: kTextGrey),
                ),
              ],
            ),
          ),
          if (checked > 0)
            GestureDetector(
              onTap: () =>
                  setState(() => _items.removeWhere((i) => i.isChecked)),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Alınanları Sil',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Input Alanı ─────────────────────────────────────────────────────────

  Widget _buildInputField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kGreen.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.add_shopping_cart_rounded,
                color: kGreen, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _inputController,
                focusNode: _inputFocus,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _addItem(),
                decoration: const InputDecoration(
                  hintText: 'Örn: 2 Litre Süt',
                  hintStyle: TextStyle(
                      fontSize: 14, color: Color(0xFFBBBBBB)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style:
                    const TextStyle(fontSize: 14, color: kTextDark),
              ),
            ),
            const SizedBox(width: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.all(7),
              child: GestureDetector(
                onTap: _addItem,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: _inputText.isNotEmpty
                        ? kGreen
                        : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: _inputText.isNotEmpty
                        ? [
                            BoxShadow(
                              color: kGreen.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    'Ekle',
                    style: TextStyle(
                      fontSize: 13,
                      color: _inputText.isNotEmpty
                          ? Colors.white
                          : const Color(0xFFAAAAAA),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Boş Durum ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ana ikon
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: kLightGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kGreen.withValues(alpha: 0.15),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.shopping_basket_outlined,
                  color: kGreen, size: 44),
            ),
            const SizedBox(height: 22),
            const Text(
              'Listeniz Henüz Boş',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: kTextDark,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Yukarıya yazarak kendi ürünlerinizi ekleyebilir\nveya aşağıdan hızlı ekleyebilirsiniz.',
              style: TextStyle(
                  fontSize: 13, color: kTextGrey, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            // Hızlı ekleme çipleri
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _suggestions.map((s) {
                final emoji = s.$1;
                final label = s.$2;
                return GestureDetector(
                  onTap: () {
                    _inputController.text = label;
                    _inputController.selection = TextSelection.fromPosition(
                      TextPosition(offset: label.length),
                    );
                    _inputFocus.requestFocus();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: kCardBg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: const Color(0xFFE8E8E8), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: kGreen.withValues(alpha: 0.07),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 15)),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: const TextStyle(
                              fontSize: 13, color: kTextDark),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Ürün Listesi ─────────────────────────────────────────────────────────

  Widget _buildItemList() {
    final unchecked = _unchecked;
    final checked = _checked;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      children: [
        // Alınmamış ürünler
        ...unchecked.map((item) => _buildTile(item)),
        // Bölüm ayracı + alınmış ürünler
        if (checked.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'Sepete Alındı (${checked.length})',
                  style: const TextStyle(
                      fontSize: 11, color: kTextGrey),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 8),
          ...checked.map((item) => _buildTile(item)),
        ],
      ],
    );
  }

  Widget _buildTile(ShoppingItem item) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded,
                color: Colors.red, size: 20),
            SizedBox(width: 4),
            Text('Sil',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      onDismissed: (_) => _removeItem(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: item.isChecked ? kLightGreen : kCardBg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: item.isChecked ? 0.02 : 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _toggleItem(item),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  // Checkbox
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: item.isChecked ? kGreen : Colors.transparent,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: item.isChecked
                            ? kGreen
                            : const Color(0xFFCCCCCC),
                        width: 2,
                      ),
                    ),
                    child: item.isChecked
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // İsim + kaynak
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: item.isChecked ? kTextGrey : kTextDark,
                            decoration: item.isChecked
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: kTextGrey,
                          ),
                        ),
                        if (item.source != 'Manuel')
                          Text(
                            item.source,
                            style: TextStyle(
                              fontSize: 11,
                              color: kTextGrey.withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Kaydırma ipucu
                  Icon(
                    item.isChecked
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: item.isChecked
                        ? kGreen
                        : const Color(0xFFDDDDDD),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Alt Butonlar ────────────────────────────────────────────────────────

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      color: kBg,
      child: _items.isEmpty
          ? _buildTumUrunlerBtn(fullWidth: true)
          : Row(
              children: [
                // İkincil: Tüm Ürünler
                Expanded(
                  child: _buildTumUrunlerBtn(),
                ),
                const SizedBox(width: 10),
                // Birincil: Listeyi Görüntüle
                Expanded(
                  flex: 2,
                  child: _buildListeGoruntuleBtn(),
                ),
              ],
            ),
    );
  }

  Widget _buildTumUrunlerBtn({bool fullWidth = false}) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TumUrunlerScreen(
            initialAddedNames:
                _items.map((i) => i.name.toLowerCase()).toSet(),
            onAddItem: (name, source) {
              final alreadyExists = _items.any(
                (i) => i.name.toLowerCase() == name.toLowerCase(),
              );
              if (!alreadyExists) {
                setState(() =>
                    _items.insert(0, ShoppingItem(name: name, source: source)));
              }
            },
          ),
        ),
      ),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kGreen, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: kGreen.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, color: kGreen, size: 18),
            const SizedBox(width: 7),
            Text(
              fullWidth ? 'Tüm Ürünleri Görüntüle' : 'Tüm Ürünler',
              style: const TextStyle(
                fontSize: 13,
                color: kGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListeGoruntuleBtn() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AlisverisGorunumScreen(
            items: List<ShoppingItem>.from(_items),
          ),
        ),
      ),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4ECE5E), kGreen],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kGreen.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 7),
            Text(
              'Görüntüle (${_items.length})',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
