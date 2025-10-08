import 'package:flutter/material.dart';

import '../models/medical_record_model.dart';
import '../utils/date_formatter.dart';

/// PUBLIC_INTERFACE
class MedicalRecordCard extends StatelessWidget {
  final MedicalRecord record;
  final VoidCallback? onTap;

  const MedicalRecordCard({super.key, required this.record, this.onTap});

  @override
  Widget build(BuildContext context) {
    final date = DateFormatter.formatDateTime(record.createdAt);
    return Card(
      child: ListTile(
        title: Text(record.title),
        subtitle: Text('${record.description}\n$date'),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
