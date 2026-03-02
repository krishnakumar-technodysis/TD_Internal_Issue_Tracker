import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/issue_entity.dart';
import 'badges.dart';

class IssueDataGrid extends StatefulWidget {
  final List<IssueEntity> issues;
  final void Function(IssueEntity) onTap;
  final void Function(IssueEntity) onEdit;

  const IssueDataGrid({
    super.key,
    required this.issues,
    required this.onTap,
    required this.onEdit,
  });

  @override
  State<IssueDataGrid> createState() => _IssueDataGridState();
}

class _IssueDataGridState extends State<IssueDataGrid> {
  final ScrollController _vertical = ScrollController();
  final ScrollController _horizontal = ScrollController();

  @override
  void dispose() {
    _vertical.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _horizontal,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _horizontal,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _L.totalWidth,
          child: Column(
            children: [
              const _Header(),

              Expanded(
                child: Scrollbar(
                  controller: _vertical,
                  thumbVisibility: true,
                  child: ListView.builder(
                    controller: _vertical,
                    itemCount: widget.issues.length,
                    itemBuilder: (_, i) => _Row(
                      issue: widget.issues[i],
                      isEven: i.isEven,
                      onTap: () => widget.onTap(widget.issues[i]),
                      onEdit: () => widget.onEdit(widget.issues[i]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ======================================================
/// PERFECT COLUMN LAYOUT
/// ======================================================

class _L {
  static const double indent   = 10;
  static const double id       = 110;
  static const double summary  = 420;
  static const double client   = 100;
  static const double priority = 90;
  static const double status   = 90;
  static const double assigned = 90;
  static const double opened   = 90;
  static const double actions  = 60;

  /// ⭐ FIXED WIDTH CALCULATION (no overflow)
  static const double totalWidth =
      indent + id + summary + client + priority + status + assigned + opened + actions + 60;
}

/// ======================================================
/// HEADER
/// ======================================================

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      color: AppTheme.textDim,
      letterSpacing: 0.8,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      decoration: BoxDecoration(
        color: AppTheme.ink.withOpacity(0.6),
        border: const Border(
          bottom: BorderSide(color: AppTheme.border),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: _L.indent),
          SizedBox(width: _L.id, child: Text('ID', style: style)),
          SizedBox(width: _L.summary, child: Text('SUMMARY', style: style)),
          SizedBox(width: _L.client, child: Text('CLIENT', style: style)),
          SizedBox(width: _L.priority, child: Text('PRIORITY', style: style)),
          SizedBox(width: _L.status, child: Text('STATUS', style: style)),
          SizedBox(width: _L.assigned, child: Text('ASSIGNED TO', style: style)),
          SizedBox(width: _L.opened, child: Text('OPENED', style: style)),
          SizedBox(width: _L.actions),
        ],
      ),
    );
  }
}

/// ======================================================
/// ROW
/// ======================================================

class _Row extends StatefulWidget {
  final IssueEntity issue;
  final bool isEven;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _Row({
    required this.issue,
    required this.isEven,
    required this.onTap,
    required this.onEdit,
  });

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final issue = widget.issue;

    final bg = widget.isEven
        ? AppTheme.inkSoft.withOpacity(0.35)
        : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.fromLTRB(20, 13, 20, 13),
          decoration: BoxDecoration(
            color: bg,
            border: Border(
              left: BorderSide(
                color: hover ? AppTheme.accent : Colors.transparent,
                width: 2,
              ),
              bottom: const BorderSide(color: Color(0x18FFFFFF)),
            ),
          ),

          /// ⭐ ENTERPRISE FIX — prevents RenderFlex overflow
          child: ClipRect(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [

                const SizedBox(width: _L.indent),

                SizedBox(
                  width: _L.id,
                  child: Text(issue.issueId,
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w600)),
                ),

                SizedBox(
                  width: _L.summary,
                  child: Text(issue.issueSummary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textColor,
                          fontWeight: FontWeight.w500)),
                ),

                SizedBox(
                  width: _L.client,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TagChip(label: issue.customer),
                    ),
                  ),
                ),

                SizedBox(
                  width: _L.priority,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: PriorityBadge(priority: issue.priority),
                    ),
                  ),
                ),

                SizedBox(
                  width: _L.status,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: StatusBadge(status: issue.status),
                    ),
                  ),
                ),

                SizedBox(
                  width: _L.assigned,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        issue.assignedTo.isEmpty ? '—' : issue.assignedTo,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textColor,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(
                  width: _L.opened,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _fmt(issue.createdAt),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10.5,
                          color: AppTheme.textDim,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(
                  width: _L.actions,
                  child: TextButton(
                    onPressed: widget.onEdit,
                    child: const Text('Edit',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w500)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.day}/${d.month}';
  }
}