import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch, // mobile
    PointerDeviceKind.mouse, // web (drag pakai mouse)
    PointerDeviceKind.trackpad, // laptop
    PointerDeviceKind.stylus,
  };
}

class ResultTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;

  final double headingRowHeight;
  final double dataRowHeight;
  final double minWidth;

  const ResultTable({
    super.key,
    required this.columns,
    required this.rows,
    this.headingRowHeight = 60,
    this.dataRowHeight = 66,
    this.minWidth = 5000,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Header gradient
            Container(
              height: headingRowHeight,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff1d63ff), Color(0xff4fa9ff)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            // 🔥 SCROLL FIX (mobile + web)
            ScrollConfiguration(
              behavior: const AppScrollBehavior(),
              child: DataTable2(
                columnSpacing: 26,
                horizontalMargin: 16,
                minWidth: minWidth,
                fixedTopRows: 1,
                headingRowHeight: headingRowHeight,
                dataRowHeight: dataRowHeight,
                headingRowColor: WidgetStateProperty.all(Colors.transparent),
                headingTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15.5,
                  letterSpacing: 0.2,
                ),
                dividerThickness: 0.6,
                dataRowColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xff1d63ff).withOpacity(0.10);
                  }
                  return Colors.transparent;
                }),
                columns: columns,
                rows: rows,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
