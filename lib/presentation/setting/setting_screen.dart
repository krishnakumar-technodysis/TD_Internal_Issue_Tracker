// lib/presentation/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:issue_tracker/presentation/setting/settings_view_model.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_sidebar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      activePage: SidebarPage.settings,
      child: DefaultTabController(
        length: 3,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Settings',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                      color: AppTheme.textColor)),
              const SizedBox(height: 2),
              const Text('Manage lookup data used across the app',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
              const SizedBox(height: 16),
              TabBar(
                labelColor: AppTheme.accent,
                unselectedLabelColor: AppTheme.textDim,
                indicatorColor: AppTheme.accent,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Clients'),
                  Tab(text: 'Technologies'),
                  Tab(text: 'Departments'),
                ],
              ),
            ]),
          ),
          const Divider(height: 1, color: AppTheme.border),
          Expanded(child: TabBarView(children: [
            _LookupTab(type: 'client'),
            _LookupTab(type: 'technology'),
            _LookupTab(type: 'department'),
          ])),
        ]),
      ),
    );
  }
}

class _LookupTab extends StatelessWidget {
  final String type;
  const _LookupTab({required this.type});

  String get label => switch (type) {
    'client'     => 'Client',
    'technology' => 'Technology',
    _            => 'Department',
  };

  Stream<List<dynamic>> _stream(SettingsViewModel vm) => switch (type) {
    'client'     => vm.clientsStream,
    'technology' => vm.technologiesStream,
    _            => vm.departmentsStream,
  };

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    return StreamBuilder<List<dynamic>>(
      stream: _stream(vm),
      builder: (context, snap) {
        final items = snap.data ?? [];
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Row(children: [
              Text('${items.length} ${label}s',
                  style: const TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showDialog(context, vm),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text('Add $label'),
              ),
            ]),
            const SizedBox(height: 16),
            if (snap.connectionState == ConnectionState.waiting)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (items.isEmpty)
              Expanded(child: Center(child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.list_alt_rounded, size: 48, color: AppTheme.textDim),
                  const SizedBox(height: 12),
                  Text('No ${label}s yet', style: const TextStyle(color: AppTheme.textMuted)),
                  const SizedBox(height: 8),
                  TextButton(onPressed: () => _showDialog(context, vm),
                      child: Text('Add first $label')),
                ],
              )))
            else
              Expanded(child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.border),
                itemBuilder: (_, i) => _ItemRow(
                  item: items[i], type: type, vm: vm,
                  onEdit: () => _showDialog(context, vm,
                      existing: items[i]),
                ),
              )),
          ]),
        );
      },
    );
  }

  void _showDialog(BuildContext ctx, SettingsViewModel vm, {dynamic existing}) {
    showDialog(context: ctx, builder: (_) => _EditDialog(
      label: label, type: type, vm: vm,
      existingId:   existing?.id,
      existingName: existing?.name,
      existingDesc: existing?.description,
    ));
  }
}

class _ItemRow extends StatelessWidget {
  final dynamic item;
  final String type;
  final SettingsViewModel vm;
  final VoidCallback onEdit;
  const _ItemRow({required this.item, required this.type,
    required this.vm, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isActive = item.isActive as bool;
    return Container(
      color: AppTheme.card,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(width: 8, height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle,
                color: isActive ? AppTheme.green : AppTheme.textDim)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.name,
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600,
                  color: isActive ? AppTheme.textColor : AppTheme.textDim,
                  decoration: isActive ? null : TextDecoration.lineThrough)),
          if (item.description != null && (item.description as String).isNotEmpty)
            Text(item.description as String,
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        ])),
        Switch(value: isActive, activeColor: AppTheme.accent,
            onChanged: (v) {
              switch (type) {
                case 'client':     vm.toggleClient(item.id, v);
                case 'technology': vm.toggleTechnology(item.id, v);
                case 'department': vm.toggleDepartment(item.id, v);
              }
            }),
        IconButton(icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.textDim),
            onPressed: onEdit),
        IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.red),
            onPressed: () => showDialog(context: context, builder: (_) => AlertDialog(
              backgroundColor: AppTheme.card,
              title: Text('Delete ${item.name}?',
                  style: const TextStyle(fontSize: 16, color: AppTheme.textColor)),
              content: Text('Remove "${item.name}"? Existing records using this will not be affected.',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                TextButton(onPressed: () {
                  Navigator.pop(context);
                  switch (type) {
                    case 'client':     vm.deleteClient(item.id);
                    case 'technology': vm.deleteTechnology(item.id);
                    case 'department': vm.deleteDepartment(item.id);
                  }
                }, child: const Text('Delete', style: TextStyle(color: AppTheme.red))),
              ],
            ))),
      ]),
    );
  }
}

class _EditDialog extends StatefulWidget {
  final String label, type;
  final SettingsViewModel vm;
  final String? existingId, existingName, existingDesc;
  const _EditDialog({required this.label, required this.type, required this.vm,
    this.existingId, this.existingName, this.existingDesc});
  @override State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final _nameCtrl = TextEditingController(text: widget.existingName ?? '');
  late final _descCtrl = TextEditingController(text: widget.existingDesc ?? '');
  bool _loading = false;

  @override void dispose() { _nameCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final name = _nameCtrl.text.trim();
      final desc = _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim();
      if (widget.existingId != null) {
        switch (widget.type) {
          case 'client':     await widget.vm.updateClient(widget.existingId!, name, desc: desc);
          case 'technology': await widget.vm.updateTechnology(widget.existingId!, name, desc: desc);
          case 'department': await widget.vm.updateDepartment(widget.existingId!, name, desc: desc);
        }
      } else {
        switch (widget.type) {
          case 'client':     await widget.vm.addClient(name, desc: desc);
          case 'technology': await widget.vm.addTechnology(name, desc: desc);
          case 'department': await widget.vm.addDepartment(name, desc: desc);
        }
      }
      if (mounted) Navigator.pop(context);
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AppTheme.card,
    title: Text('${widget.existingId != null ? 'Edit' : 'Add'} ${widget.label}',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textColor)),
    content: SizedBox(width: 360, child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: _nameCtrl, autofocus: true,
          style: const TextStyle(color: AppTheme.textColor),
          decoration: InputDecoration(
              labelText: '${widget.label} Name *',
              labelStyle: const TextStyle(color: AppTheme.textMuted))),
      const SizedBox(height: 12),
      TextField(controller: _descCtrl,
          style: const TextStyle(color: AppTheme.textColor),
          decoration: const InputDecoration(
              labelText: 'Description (optional)',
              labelStyle: TextStyle(color: AppTheme.textMuted))),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ElevatedButton(onPressed: _loading ? null : _save,
          child: _loading
              ? const SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save')),
    ],
  );
}