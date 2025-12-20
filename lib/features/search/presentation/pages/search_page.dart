import 'package:flutter/material.dart';
import 'package:cleanapp/core/data/services_data.dart';
import 'package:cleanapp/core/models/service.dart';
import 'package:cleanapp/core/widgets/bottom_nav_bar.dart';
import 'package:go_router/go_router.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'all';
  String _quickFilter = 'all';
  List<Service> _results = ServicesData.services;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _performSearch();
  }

  void _performSearch() {
    setState(() {
      _results = ServicesData.searchServices(
        query: _searchController.text,
        categoryFilter: _selectedCategory,
        quickFilter: _quickFilter,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск услуг'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск услуг...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Category Filter
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: ServicesData.categories.length,
              itemBuilder: (context, index) {
                final category = ServicesData.categories[index];
                final isSelected = _selectedCategory == category.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category.id;
                        _performSearch();
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // Quick Filters
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 3,
              itemBuilder: (context, index) {
                final filters = [
                  {'id': 'all', 'label': 'Все'},
                  {'id': 'top', 'label': 'Топ'},
                  {'id': 'popular', 'label': 'Популярные'},
                ];
                final filter = filters[index];
                final isSelected = _quickFilter == filter['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter['label']!),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _quickFilter = filter['id']!;
                        _performSearch();
                      });
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Results
          Expanded(
            child: _results.isEmpty
                ? const Center(
                    child: Text('Ничего не найдено'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final service = _results[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(service.icon),
                          ),
                          title: Text(service.name),
                          subtitle: Text(service.price),
                          trailing: service.isTop
                              ? Chip(
                                  label: const Text('Топ'),
                                  backgroundColor: Colors.amber[100],
                                )
                              : null,
                          onTap: () {
                            if (service.tariffId != null) {
                              context.go('/tariff/${service.tariffId}');
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}

