import 'package:flutter/material.dart';

enum DateRangeMonths { one, three, six, twelve }

extension DateRangeMonthsExt on DateRangeMonths {
  int get months {
    switch (this) {
      case DateRangeMonths.one:
        return 1;
      case DateRangeMonths.three:
        return 3;
      case DateRangeMonths.six:
        return 6;
      case DateRangeMonths.twelve:
        return 12;
    }
  }

  String get label {
    switch (this) {
      case DateRangeMonths.one:
        return 'Past 1 month';
      case DateRangeMonths.three:
        return 'Past 3 months';
      case DateRangeMonths.six:
        return 'Past 6 months';
      case DateRangeMonths.twelve:
        return 'Past 1 year';
    }
  }
}

class DateRangeSelector extends StatelessWidget {
  final DateRangeMonths value;
  final ValueChanged<DateRangeMonths> onChanged;

  const DateRangeSelector({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<DateRangeMonths>(
      value: value,
      borderRadius: BorderRadius.circular(8),
      items: DateRangeMonths.values
          .map(
            (e) => DropdownMenuItem<DateRangeMonths>(
              value: e,
              child: Text(e.label),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}


