import 'package:flutter/material.dart';
import 'package:safety_apps/widgets/result/date_preset.dart';
import 'package:safety_apps/widgets/result/page_style.dart';

Future<void> openDateFilterModal({
  required BuildContext context,
  required DatePreset selectedPreset,
  required VoidCallback onSelectAll,
  required VoidCallback onSelectToday,
  required VoidCallback onSelectWeek,
  required VoidCallback onSelectMonth,
  required Future<void> Function() onSelectCustom,
}) async {
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) {
      return Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.10),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.tune_rounded),
                const SizedBox(width: 10),
                const Text(
                  "Pilih Filter Tanggal",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ResultModalItem(
              text: "Semua tanggal",
              preset: DatePreset.all,
              selectedPreset: selectedPreset,
              onTap: onSelectAll,
            ),
            ResultModalItem(
              text: "Hari ini",
              preset: DatePreset.today,
              selectedPreset: selectedPreset,
              onTap: onSelectToday,
            ),
            ResultModalItem(
              text: "Minggu ini",
              preset: DatePreset.week,
              selectedPreset: selectedPreset,
              onTap: onSelectWeek,
            ),
            ResultModalItem(
              text: "Bulan ini",
              preset: DatePreset.month,
              selectedPreset: selectedPreset,
              onTap: onSelectMonth,
            ),
            ResultModalItem(
              text: "Custom range…",
              preset: DatePreset.custom,
              selectedPreset: selectedPreset,
              onTap: () async {
                await onSelectCustom();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      );
    },
  );
}

class ResultModalItem extends StatelessWidget {
  final String text;
  final DatePreset preset;
  final DatePreset selectedPreset;
  final VoidCallback onTap;

  const ResultModalItem({
    super.key,
    required this.text,
    required this.preset,
    required this.selectedPreset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedPreset == preset;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? ResultPageStyle.primary.withOpacity(0.08)
              : const Color(0xfff5f7fb),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected
                  ? ResultPageStyle.primary
                  : Colors.black.withOpacity(0.35),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
