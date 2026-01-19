import '../templates.dart';

class TemplatesHomeScreen extends StatefulWidget {
  const TemplatesHomeScreen({super.key});

  @override
  State<TemplatesHomeScreen> createState() => _TemplatesHomeScreenState();
}

class _TemplatesHomeScreenState extends State<TemplatesHomeScreen> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  late final Future<List<VideoTemplate>> _templatesFuture;

  String _category = 'For you';

  static const _defaultCategories = <String>[
    'For you',
    'New',
  ];

  @override
  void initState() {
    super.initState();
    _templatesFuture = const TemplateRepository().loadTemplates();

    // Rebuild list when text changes, without recreating the TextField.

    _search.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    _search.dispose();
    super.dispose();
  }

  List<String> _buildCategories(List<VideoTemplate> templates) {
    final fromData = <String>{};
    for (final t in templates) {
      final c = t.category.trim();
      if (c.isNotEmpty) fromData.add(c);
    }

    final ordered = <String>[];
    for (final c in _defaultCategories) {
      if (fromData.contains(c) || c == 'For you') ordered.add(c);
    }

    final rest = fromData
        .where((c) => !ordered.contains(c))
        .toList(growable: false)
      ..sort();

    ordered.addAll(rest);
    return ordered;
  }

  List<VideoTemplate> _filterTemplates(List<VideoTemplate> templates) {
    final q = _search.text.trim().toLowerCase();

    Iterable<VideoTemplate> out = templates;

    if (_category != 'For you') {
      out = out.where((t) => t.category.toLowerCase() == _category.toLowerCase());
    }

    if (q.isNotEmpty) {
      out = out.where((t) {
        return t.title.toLowerCase().contains(q) || t.id.toLowerCase().contains(q);
      });
    }

    return out.toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<List<VideoTemplate>>(
          future: _templatesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Failed to load templates\n${snapshot.error}',
                    style: const TextStyle(color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final templates = snapshot.data ?? const [];
            final categories = _buildCategories(templates);

            // Ensure current category still exists.
            if (!categories.contains(_category)) {
              _category = categories.isNotEmpty ? categories.first : 'For you';
            }

            final filtered = _filterTemplates(templates);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.grid_view_rounded, color: Colors.black87, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SearchField(
                          controller: _search,
                          focusNode: _searchFocus,
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: () {
                          _search.clear();
                          // Keep the keyboard open if user is searching.
                          _searchFocus.requestFocus();
                        },
                        icon: const Icon(Icons.refresh_rounded, color: Colors.black87),
                        tooltip: 'Reset search',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                _CategoryTabs(
                  categories: categories,
                  selected: _category,
                  onSelected: (c) => setState(() => _category = c),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text(
                            'No templates found',
                            style: TextStyle(color: Colors.black54),
                          ),
                        )
                      : GridView.builder(
                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            // Taller cards like CapCut (so ~4 cards visible on most phones)
                            childAspectRatio: 0.62,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final t = filtered[i];
                            return TemplateCard(
                              template: t,
                              onTap: () {
                                FocusScope.of(context).unfocus();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TemplateDetailScreen(template: t),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const _SearchField({
    required this.controller,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.black54, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              key: const ValueKey('templates_search_field'),
              controller: controller,
              focusNode: focusNode,
              // Keep focus across rebuilds.
              autofocus: false,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search templates',
                hintStyle: TextStyle(color: Colors.black45),
              ),
              style: const TextStyle(color: Colors.black87, fontSize: 14),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                focusNode.requestFocus();
              },
              child: const Icon(Icons.close_rounded, color: Colors.black54, size: 18),
            ),
        ],
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  const _CategoryTabs({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final c = categories[i];
          final isSelected = c == selected;

          return GestureDetector(
            onTap: () => onSelected(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Text(
                c,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
