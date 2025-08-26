import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateLabel extends StatelessWidget {
  final DateTime date;
  const DateLabel({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final f = DateFormat('EEEE d MMMM yyyy');
    return Text('Starting ${f.format(date)}');
  }
}
