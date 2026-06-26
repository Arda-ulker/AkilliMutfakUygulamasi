import 'package:flutter/material.dart';
import 'package:akilli_mutfak/constants/app_colors.dart';
import 'package:akilli_mutfak/models/shopping_item.dart';

class AlisverisGorunumScreen extends StatelessWidget {
  final List<ShoppingItem> items;

  const AlisverisGorunumScreen({super.key, required this.items});

  Map<String, List<ShoppingItem>> _groupByAisle() {
    final Map<String, List<ShoppingItem>> grouped = {};
    for (final item in items) {
      grouped.putIfAbsent(getAisle(item.name), () => []).add(item);
    }
    final Map<String, List<ShoppingItem>> ordered = {};
    for (final aisle in kAisleOrder) {
      if (grouped.containsKey(aisle)) ordered[aisle] = grouped[aisle]!;
    }
    return ordered;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByAisle();
    final checkedCount = items.where((i) => i.isChecked).length;

    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildAppBar(context, checkedCount),
      body: items.isEmpty
          ? _buildEmptyView()
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: grouped.length,
              itemBuilder: (_, sectionIdx) {
                final aisle = grouped.keys.elementAt(sectionIdx);
                final sectionItems = grouped[aisle]!;
                final sectionChecked =
                    sectionItems.where((i) => i.isChecked).length;
                final allDone = sectionChecked == sectionItems.length;

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: kCardBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: kGreen.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Reyon başlığı
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                        child: Row(
                          children: [
                            Text(
                              aisle,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: allDone ? kTextGrey : kTextDark,
                                decoration: allDone
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: kTextGrey,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: allDone
                                    ? kGreen.withValues(alpha: 0.12)
                                    : kBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$sectionChecked / ${sectionItems.length}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: allDone ? kGreen : kTextGrey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, indent: 14, endIndent: 14),
                      // Ürünler
                      ...sectionItems.asMap().entries.map((e) {
                        final isLast = e.key == sectionItems.length - 1;
                        return _buildItemRow(e.value, isLast: isLast);
                      }),
                    ],
                  ),
                );
              },
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, int checkedCount) {
    return AppBar(
      backgroundColor: kCardBg,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: kTextDark),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alışveriş Listesi',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: kTextDark),
          ),
          Text(
            '$checkedCount / ${items.length} ürün sepete alındı',
            style: const TextStyle(fontSize: 11, color: kTextGrey),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFEEEEEE)),
      ),
    );
  }

  Widget _buildItemRow(ShoppingItem item, {bool isLast = false}) {
    return Container(
      decoration: BoxDecoration(
        color: item.isChecked ? kLightGreen : Colors.transparent,
        borderRadius: isLast
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              )
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Renk noktası / onay simgesi
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: item.isChecked
                ? const Icon(Icons.check_circle_rounded,
                    key: ValueKey(true), color: kGreen, size: 18)
                : Container(
                    key: const ValueKey(false),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: kGreen,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
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
                    decoration:
                        item.isChecked ? TextDecoration.lineThrough : null,
                    decorationColor: kTextGrey,
                  ),
                ),
                if (item.source != 'Manuel')
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item.source,
                      style: TextStyle(
                        fontSize: 11,
                        color: kTextGrey.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (item.isChecked)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: kGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Alındı',
                style: TextStyle(
                    fontSize: 10,
                    color: kGreen,
                    fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 52, color: kTextGrey),
          SizedBox(height: 12),
          Text('Liste boş',
              style: TextStyle(fontSize: 15, color: kTextGrey)),
        ],
      ),
    );
  }
}
