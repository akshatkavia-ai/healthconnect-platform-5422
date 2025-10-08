import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/medical_record_provider.dart';
import '../../widgets/loading_indicator.dart';

/// PUBLIC_INTERFACE
class MedicalRecordDetailScreen extends StatelessWidget {
  final String id;
  const MedicalRecordDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MedicalRecordProvider>();

    if (!provider.loading && (provider.selected == null || provider.selected!.id != id)) {
      // Avoid BuildContext across async gaps by using the provider reference directly
      Future.microtask(() => provider.getById(id));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Record Details')),
      body: provider.loading || provider.selected == null
          ? const LoadingIndicator()
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: ListTile(
                  title: Text(provider.selected!.title),
                  subtitle: Text(provider.selected!.description),
                ),
              ),
            ),
    );
  }
}
