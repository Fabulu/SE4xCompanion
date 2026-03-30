import 'dart:async';

import 'package:flutter/material.dart';

import '../data/rules_data.dart';
import '../data/rules_phases.dart';
import '../widgets/rule_text.dart';

enum _ViewMode { phase, full, search }

class RulesReferencePage extends StatefulWidget {
  const RulesReferencePage({super.key});

  @override
  State<RulesReferencePage> createState() => RulesReferencePageState();
}

class RulesReferencePageState extends State<RulesReferencePage> {
  _ViewMode _viewMode = _ViewMode.full;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  String _searchQuery = '';
  List<RuleSection> _searchResults = [];

  // Expansion state
  final Set<String> _expandedSections = {};
  final Set<String> _expandedPhases = {};

  // Keys for scroll-to-section
  final Map<String, GlobalKey> _sectionKeys = {};

  // Precomputed parent hierarchy: top-level sections and their children
  late final List<RuleSection> _topLevel;
  late final Map<String, List<RuleSection>> _childrenOf;

  @override
  void initState() {
    super.initState();
    _topLevel = kAllRules.where((r) => r.depth == 0).toList();
    _childrenOf = {};
    for (final rule in kAllRules) {
      if (rule.parentId != null) {
        _childrenOf.putIfAbsent(rule.parentId!, () => []).add(rule);
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(String sectionId) {
    return _sectionKeys.putIfAbsent(sectionId, () => GlobalKey());
  }

  // ---------------------------------------------------------------------------
  // Public API for external navigation
  // ---------------------------------------------------------------------------

  void jumpToSection(String sectionId) {
    // Clear search
    _searchController.clear();
    _searchQuery = '';
    _searchResults = [];

    // Switch to full view
    _viewMode = _ViewMode.full;

    // Expand parent chain
    _expandParentChain(sectionId);

    // Expand the section itself so its body is visible
    _expandedSections.add(sectionId);

    setState(() {});

    // Scroll after the frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSection(sectionId);
    });
  }

  void _expandParentChain(String sectionId) {
    final rule = kRulesById[sectionId];
    if (rule == null) return;

    // Walk up the parent chain and expand each ancestor
    String? currentId = rule.parentId;
    while (currentId != null) {
      _expandedSections.add(currentId);
      final parent = kRulesById[currentId];
      currentId = parent?.parentId;
    }
  }

  void _scrollToSection(String sectionId) {
    final key = _sectionKeys[sectionId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Search
  // ---------------------------------------------------------------------------

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final query = value.trim().toLowerCase();
      if (query.isEmpty) {
        setState(() {
          _searchQuery = '';
          _searchResults = [];
          _viewMode = _ViewMode.full;
        });
        return;
      }
      final results = kAllRules.where((r) {
        return r.title.toLowerCase().contains(query) ||
            r.body.toLowerCase().contains(query) ||
            r.id.startsWith(query);
      }).toList();
      setState(() {
        _searchQuery = query;
        _searchResults = results;
        _viewMode = _ViewMode.search;
      });
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _searchResults = [];
      if (_viewMode == _ViewMode.search) {
        _viewMode = _ViewMode.full;
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Cross-reference tap
  // ---------------------------------------------------------------------------

  void _onReferenceTap(String sectionId) {
    jumpToSection(sectionId);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search rules...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: _clearSearch,
                    )
                  : null,
            ),
          ),
        ),

        // View mode toggle (only visible when not searching)
        if (_viewMode != _ViewMode.search)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                _ModeChip(
                  label: 'Full',
                  selected: _viewMode == _ViewMode.full,
                  onTap: () => setState(() => _viewMode = _ViewMode.full),
                ),
                const SizedBox(width: 8),
                _ModeChip(
                  label: 'By Phase',
                  selected: _viewMode == _ViewMode.phase,
                  onTap: () => setState(() => _viewMode = _ViewMode.phase),
                ),
              ],
            ),
          ),

        // Search results count
        if (_viewMode == _ViewMode.search)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_searchResults.length} result${_searchResults.length == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),

        // Content
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 80),
              children: _buildContent(),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildContent() {
    switch (_viewMode) {
      case _ViewMode.search:
        return _buildSearchResults();
      case _ViewMode.phase:
        return _buildPhaseView();
      case _ViewMode.full:
        return _buildFullView();
    }
  }

  // ---------------------------------------------------------------------------
  // Full view
  // ---------------------------------------------------------------------------

  List<Widget> _buildFullView() {
    final widgets = <Widget>[];
    for (final section in _topLevel) {
      widgets.addAll(_buildSectionTree(section, 0));
    }
    return widgets;
  }

  List<Widget> _buildSectionTree(RuleSection section, int indent) {
    final isExpanded = _expandedSections.contains(section.id);
    final children = _childrenOf[section.id] ?? [];
    final hasChildren = children.isNotEmpty || section.body.trim().isNotEmpty;

    final widgets = <Widget>[
      _RuleSectionTile(
        key: _keyFor(section.id),
        section: section,
        indent: indent,
        isExpanded: isExpanded,
        hasChildren: hasChildren,
        onTap: hasChildren
            ? () {
                setState(() {
                  if (isExpanded) {
                    _expandedSections.remove(section.id);
                  } else {
                    _expandedSections.add(section.id);
                  }
                });
              }
            : null,
        bodyWidget: isExpanded && section.body.trim().isNotEmpty
            ? Padding(
                padding: EdgeInsets.fromLTRB(16.0 + indent * 12, 0, 16, 8),
                child: RuleTextWidget(
                  text: section.body.trim(),
                  onReferenceTap: _onReferenceTap,
                ),
              )
            : null,
      ),
    ];

    if (isExpanded) {
      for (final child in children) {
        widgets.addAll(_buildSectionTree(child, indent + 1));
      }
    }

    return widgets;
  }

  // ---------------------------------------------------------------------------
  // Phase view
  // ---------------------------------------------------------------------------

  List<Widget> _buildPhaseView() {
    final widgets = <Widget>[];
    for (final entry in kPhaseGroupings.entries) {
      final phaseName = entry.key;
      final sectionIds = entry.value;
      final isExpanded = _expandedPhases.contains(phaseName);

      widgets.add(
        _PhaseHeader(
          title: phaseName,
          count: sectionIds.length,
          isExpanded: isExpanded,
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedPhases.remove(phaseName);
              } else {
                _expandedPhases.add(phaseName);
              }
            });
          },
        ),
      );

      if (isExpanded) {
        for (final id in sectionIds) {
          final section = kRulesById[id];
          if (section == null) continue;
          final isSectionExpanded = _expandedSections.contains(id);
          widgets.add(
            _RuleSectionTile(
              key: _keyFor(id),
              section: section,
              indent: 0,
              isExpanded: isSectionExpanded,
              hasChildren: section.body.trim().isNotEmpty,
              onTap: section.body.trim().isNotEmpty
                  ? () {
                      setState(() {
                        if (isSectionExpanded) {
                          _expandedSections.remove(id);
                        } else {
                          _expandedSections.add(id);
                        }
                      });
                    }
                  : null,
              bodyWidget: isSectionExpanded && section.body.trim().isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: RuleTextWidget(
                        text: section.body.trim(),
                        onReferenceTap: _onReferenceTap,
                      ),
                    )
                  : null,
            ),
          );
        }
      }
    }
    return widgets;
  }

  // ---------------------------------------------------------------------------
  // Search results
  // ---------------------------------------------------------------------------

  List<Widget> _buildSearchResults() {
    return _searchResults.map((section) {
      final isExpanded = _expandedSections.contains(section.id);
      return _RuleSectionTile(
        key: _keyFor(section.id),
        section: section,
        indent: 0,
        isExpanded: isExpanded,
        hasChildren: section.body.trim().isNotEmpty,
        onTap: section.body.trim().isNotEmpty
            ? () {
                setState(() {
                  if (isExpanded) {
                    _expandedSections.remove(section.id);
                  } else {
                    _expandedSections.add(section.id);
                  }
                });
              }
            : null,
        bodyWidget: isExpanded && section.body.trim().isNotEmpty
            ? Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: RuleTextWidget(
                  text: section.body.trim(),
                  onReferenceTap: _onReferenceTap,
                ),
              )
            : null,
      );
    }).toList();
  }
}

// =============================================================================
// Section tile widget
// =============================================================================

class _RuleSectionTile extends StatelessWidget {
  final RuleSection section;
  final int indent;
  final bool isExpanded;
  final bool hasChildren;
  final VoidCallback? onTap;
  final Widget? bodyWidget;

  const _RuleSectionTile({
    super.key,
    required this.section,
    required this.indent,
    required this.isExpanded,
    required this.hasChildren,
    this.onTap,
    this.bodyWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(12.0 + indent * 12, 10, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section number
                SizedBox(
                  width: 52,
                  child: Text(
                    section.id,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                // Title + optional badge
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          section.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (section.isOptional) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'OPT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Expand indicator
                if (hasChildren)
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
              ],
            ),
          ),
        ),
        ?bodyWidget,
        Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.5)),
      ],
    );
  }
}

// =============================================================================
// Phase header
// =============================================================================

class _PhaseHeader extends StatelessWidget {
  final String title;
  final int count;
  final bool isExpanded;
  final VoidCallback onTap;

  const _PhaseHeader({
    required this.title,
    required this.count,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          border: Border(
            bottom: BorderSide(color: theme.dividerColor, width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              size: 22,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Mode chip
// =============================================================================

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}
