import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/user_model.dart';

class RoleSelector extends StatelessWidget {
  const RoleSelector({super.key, required this.role, required this.onChanged});

  final UserRole role;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<UserRole>(
      segments: const [
        ButtonSegment(
          value: UserRole.tenant,
          label: Text('Locataire'),
          icon: Icon(Icons.key_outlined),
        ),
        ButtonSegment(
          value: UserRole.owner,
          label: Text('Propriétaire'),
          icon: Icon(Icons.apartment_outlined),
        ),
      ],
      selected: {role},
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: AppColors.primary,
        selectedForegroundColor: Colors.white,
      ),
    );
  }
}
