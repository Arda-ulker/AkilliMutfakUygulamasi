/// Alışveriş listesi öğesi.
class ShoppingItem {
  final String id;
  String name;
  String source; // 'Manuel' ya da tarif adı
  bool isChecked;

  ShoppingItem({
    required this.name,
    this.source = 'Manuel',
    this.isChecked = false,
  }) : id = '${name}_${DateTime.now().microsecondsSinceEpoch}';
}

/// Reyonların gösterilme sırası.
const List<String> kAisleOrder = [
  '🥬 Sebze',
  '🥩 Et & Tavuk',
  '🐟 Balık & Deniz',
  '🧀 Süt & Peynir',
  '🥚 Yumurta',
  '🧈 Tereyağı',
  '🍋 Meyve & Zeytin',
  '🫘 Bakliyat',
  '🍚 Tahıl & Makarna',
  '🍞 Unlu Mamul',
  '🧴 Yağ',
  '🥫 Sos & Konserve',
  '🌶️ Baharat',
  '🍰 Tatlı & Şeker',
  '🥜 Kuruyemiş',
  '🛒 Diğer',
];

/// Malzeme adına göre reyon döndürür.
String getAisle(String ingredient) {
  final lower = ingredient.toLowerCase();
  bool has(List<String> kws) => kws.any((k) => lower.contains(k));

  if (has(['yumurta'])) return '🥚 Yumurta';
  if (has(['tereyağ', 'margarin'])) return '🧈 Tereyağı';
  if (has(['süt', 'yoğurt', 'peynir', 'kaymak', 'krema', 'lor', 'mozzarella', 'kaşar', 'labne', 'ayran', 'kefir'])) return '🧀 Süt & Peynir';
  if (has(['kıyma', 'tavuk', 'kuzu', 'dana', 'biftek', 'sucuk', 'sosis', 'jambon', 'pastırma', 'hindi', 'bonfile', 'pirzola', 'antrikot', 'ciğer'])) return '🥩 Et & Tavuk';
  if (has(['balık', 'karides', 'midye', 'ahtapot', 'levrek', 'çipura', 'hamsi', 'somon', 'palamut', 'uskumru', 'sardalya'])) return '🐟 Balık & Deniz';
  // Baharat check, "pul biber" → Baharat'a girer, plain "biber" → Sebze'ye geçer
  if (has(['tuz', 'karabiber', 'pul biber', 'kimyon', 'tarçın', 'zerdeçal', 'kekik', 'fesleğen', 'biberiye', 'köri', 'kakule', 'baharat', 'vanilya', 'karbonat', 'kabartma', 'limon tuzu'])) return '🌶️ Baharat';
  if (has(['soğan', 'sarımsak', 'domates', 'patlıcan', 'kabak', 'havuç', 'patates', 'ıspanak', 'lahana', 'brokoli', 'salatalık', 'marul', 'kereviz', 'pırasa', 'enginar', 'karnabahar', 'mantar', 'roka', 'maydanoz', 'nane', 'dereotu', 'kişniş', 'pancar', 'turp', 'semizotu', 'biber'])) return '🥬 Sebze';
  if (has(['elma', 'portakal', 'limon', 'muz', 'çilek', 'üzüm', 'kiraz', 'karpuz', 'kavun', 'armut', 'şeftali', 'kayısı', 'erik', 'incir', 'nar', 'mandalina', 'greyfurt', 'mango', 'ananas', 'zeytin'])) return '🍋 Meyve & Zeytin';
  if (has(['mercimek', 'nohut', 'barbunya', 'börülce', 'fasulye', 'bakla'])) return '🫘 Bakliyat';
  if (has(['makarna', 'pirinç', 'bulgur', 'irmik', 'erişte', 'şehriye'])) return '🍚 Tahıl & Makarna';
  if (has(['ekmek', 'yufka', 'pide', 'lavaş', 'kadayıf', 'galeta', 'nişasta'])) return '🍞 Unlu Mamul';
  if (RegExp(r'\bun\b').hasMatch(lower)) return '🍞 Unlu Mamul';
  if (has(['zeytinyağ', 'ayçiçek yağ', 'mısır yağ', 'sıvıyağ'])) return '🧴 Yağ';
  if (has(['salça', 'konserve', 'ketçap', 'mayonez', 'hardal', 'sirke', 'turşu'])) return '🥫 Sos & Konserve';
  if (has(['şeker', 'pudra', 'çikolata', 'kakao', 'bal', 'pekmez', 'reçel'])) return '🍰 Tatlı & Şeker';
  if (has(['ceviz', 'fındık', 'badem', 'fıstık', 'susam', 'tahin', 'antep'])) return '🥜 Kuruyemiş';
  if (has(['yağ'])) return '🧴 Yağ';
  if (has(['sos', 'maya'])) return '🥫 Sos & Konserve';
  return '🛒 Diğer';
}
