import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:karta_shared/karta_shared.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../widgets/event_card.dart';
import '../../widgets/category_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategory;
  String? _selectedCity;
  bool _hasActiveFilters = false;
  Timer? _searchDebounce;

  // Categories
  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.sports_soccer, 'label': 'Sport', 'value': 'Sport'},
    {'icon': Icons.theater_comedy, 'label': 'Culture', 'value': 'Culture'},
    {'icon': Icons.music_note, 'label': 'Music', 'value': 'Music'},
    {'icon': Icons.movie, 'label': 'Film', 'value': 'Film'},
  ];

  // Popular cities
  final List<String> _popularCities = [
    'Sarajevo',
    'Mostar',
    'Zenica',
    'Tuzla',
    'Banjaluka',
    'Trebinje',
  ];

  // Test data - only used in demo mode
  final bool _useTestData = false; // Use real API data from database
  
  List<EventDto> _getTestEvents() {
    final now = DateTime.now();
    return [
      EventDto(
        id: '1',
        title: 'Event long name - Kulturna predstava u centru',
        slug: 'kulturna-predstava-centar',
        description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. In sed orci vestibulum, pharetra sapien sed, dictum nulla. Nulla dignissim, risus a porta mattis, nisl et porta orci. Nam nec libero non mauris volutpat porttitor.',
        startsAt: now.add(const Duration(days: 7)),
        endsAt: now.add(const Duration(days: 7, hours: 3)),
        venue: 'Kamerni teatar 55',
        city: 'Sarajevo',
        country: 'Bosnia and Herzegovina',
        category: 'Culture',
        status: 'Published',
        createdAt: now.subtract(const Duration(days: 30)),
        priceTiers: [
          const PriceTierDto(
            id: '1',
            name: 'Standard',
            price: 15.0,
            currency: 'KM',
            capacity: 100,
            sold: 50,
          ),
        ],
        coverImageUrl: null,
      ),
      EventDto(
        id: '2',
        title: 'Teatar predstava - Večernja scena',
        slug: 'teatar-predstava-vecernja',
        description: 'Opis druge predstave sa dugim tekstom.',
        startsAt: now.add(const Duration(days: 10)),
        endsAt: now.add(const Duration(days: 10, hours: 2)),
        venue: 'Narodno pozorište',
        city: 'Sarajevo',
        country: 'Bosnia and Herzegovina',
        category: 'Culture',
        status: 'Published',
        createdAt: now.subtract(const Duration(days: 25)),
        priceTiers: [
          const PriceTierDto(
            id: '2',
            name: 'Standard',
            price: 20.0,
            currency: 'KM',
            capacity: 150,
            sold: 50,
          ),
        ],
        coverImageUrl: null,
      ),
      EventDto(
        id: '3',
        title: 'FK Sarajevo vs FK Željezničar - Derby',
        slug: 'sarajevo-vs-zeljeznicar-derby',
        description: 'Najveći derbi u BiH.',
        startsAt: now.add(const Duration(days: 5)),
        endsAt: now.add(const Duration(days: 5, hours: 2)),
        venue: 'Olimpijski stadion Asim Ferhatović Hase',
        city: 'Sarajevo',
        country: 'Bosnia and Herzegovina',
        category: 'Sport',
        status: 'Published',
        createdAt: now.subtract(const Duration(days: 20)),
        priceTiers: [
          const PriceTierDto(
            id: '3',
            name: 'Zapad',
            price: 10.0,
            currency: 'KM',
            capacity: 500,
            sold: 300,
          ),
          const PriceTierDto(
            id: '4',
            name: 'Istok',
            price: 15.0,
            currency: 'KM',
            capacity: 500,
            sold: 200,
          ),
        ],
        coverImageUrl: null,
      ),
      EventDto(
        id: '4',
        title: 'Košarkaška utakmica - KK Bosna vs KK Igokea',
        slug: 'kosarka-bosna-vs-igokea',
        description: 'Regionalna košarkaška liga.',
        startsAt: now.add(const Duration(days: 8)),
        endsAt: now.add(const Duration(days: 8, hours: 2)),
        venue: 'Dvorana Mirza Delibašić',
        city: 'Sarajevo',
        country: 'Bosnia and Herzegovina',
        category: 'Sport',
        status: 'Published',
        createdAt: now.subtract(const Duration(days: 15)),
        priceTiers: [
          const PriceTierDto(
            id: '5',
            name: 'Standard',
            price: 12.0,
            currency: 'KM',
            capacity: 300,
            sold: 150,
          ),
        ],
        coverImageUrl: null,
      ),
      EventDto(
        id: '5',
        title: 'Koncert klasične muzike',
        slug: 'koncert-klasicne-muzike',
        description: 'Sarajevska filharmonija izvodi Mocarta.',
        startsAt: now.add(const Duration(days: 15)),
        endsAt: now.add(const Duration(days: 15, hours: 2)),
        venue: 'Kamerni teatar 55',
        city: 'Sarajevo',
        country: 'Bosnia and Herzegovina',
        category: 'Music',
        status: 'Published',
        createdAt: now.subtract(const Duration(days: 10)),
        priceTiers: [
          const PriceTierDto(
            id: '6',
            name: 'Standard',
            price: 25.0,
            currency: 'KM',
            capacity: 200,
            sold: 120,
          ),
        ],
        coverImageUrl: null,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    // Always try to load real events, fallback to test data only in demo mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_useTestData) {
        _loadEvents();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    final eventProvider = context.read<EventProvider>();
    // Use public endpoint - no authentication required for browsing events
    await eventProvider.loadEvents(
      query: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      category: _selectedCategory,
      city: _selectedCity,
      usePublicEndpoint: true, // Use public API endpoint
    );
  }

  void _onCategorySelected(String? category) {
    setState(() {
      _selectedCategory = category == _selectedCategory ? null : category;
      _updateActiveFilters();
    });
    _applyFilters();
  }

  void _onCitySelected(String city) {
    setState(() {
      _selectedCity = city == _selectedCity ? null : city;
      _updateActiveFilters();
    });
    _applyFilters();
  }

  void _updateActiveFilters() {
    _hasActiveFilters = _selectedCategory != null || 
                        _selectedCity != null || 
                        _searchController.text.trim().isNotEmpty;
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedCity = null;
      _searchController.clear();
      _hasActiveFilters = false;
    });
    _applyFilters();
  }

  void _applyFilters() {
    _updateActiveFilters();
    _loadEvents();
  }

  List<EventDto> _getEventsByCategory(List<EventDto> events, String category) {
    return events
        .where((e) => e.category == category && e.isPublished && !e.isDraft)
        .take(10)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              backgroundColor: Colors.white,
              elevation: 0,
              title: Text(
                'karta.ba',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    _showMenu(context);
                  },
                ),
              ],
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search events',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilters();
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    // Update active filters state when typing
                    setState(() {
                      _updateActiveFilters();
                    });
                    
                    // Cancel previous debounce timer
                    _searchDebounce?.cancel();
                    
                    // If search is empty, apply filters immediately
                    if (value.trim().isEmpty) {
                      _applyFilters();
                    } else {
                      // Debounce search - wait 500ms after user stops typing
                      _searchDebounce = Timer(const Duration(milliseconds: 500), () {
                        if (mounted) {
                          _applyFilters();
                        }
                      });
                    }
                  },
                  onSubmitted: (_) {
                    _searchDebounce?.cancel();
                    _applyFilters();
                  },
                ),
              ),
            ),

            // Active Filters Bar
            if (_hasActiveFilters)
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (_selectedCategory != null)
                                Chip(
                                  label: Text(_selectedCategory!),
                                  avatar: Icon(
                                    _categories.firstWhere((c) => c['value'] == _selectedCategory)['icon'] as IconData,
                                    size: 18,
                                  ),
                                  onDeleted: () => _onCategorySelected(_selectedCategory),
                                  deleteIcon: const Icon(Icons.close, size: 18),
                                ),
                              if (_selectedCity != null) ...[
                                const SizedBox(width: 8),
                                Chip(
                                  label: Text(_selectedCity!),
                                  avatar: const Icon(Icons.location_on, size: 18),
                                  onDeleted: () => _onCitySelected(_selectedCity!),
                                  deleteIcon: const Icon(Icons.close, size: 18),
                                ),
                              ],
                              if (_searchController.text.trim().isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Chip(
                                  label: Text('"${_searchController.text.trim()}"'),
                                  avatar: const Icon(Icons.search, size: 18),
                                  onDeleted: () {
                                    _searchController.clear();
                                    _applyFilters();
                                  },
                                  deleteIcon: const Icon(Icons.close, size: 18),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: const Text('Clear all'),
                      ),
                    ],
                  ),
                ),
              ),

            // Hero Banner
            SliverToBoxAdapter(
              child: Container(
                height: 200,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundGray,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 64,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ),
            ),

            // Categories
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Categories',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          return CategoryButton(
                            icon: category['icon'] as IconData,
                            label: category['label'] as String,
                            isSelected: _selectedCategory == category['value'],
                            onTap: () => _onCategorySelected(category['value'] as String),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Events by Category
            _useTestData
                ? SliverToBoxAdapter(
                    child: _buildTestEventsList(),
                  )
                : Consumer<EventProvider>(
                    builder: (context, eventProvider, child) {
                      if (eventProvider.isLoading) {
                        return const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        );
                      }

                      if (eventProvider.error != null) {
                        return SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Text(
                                    'Error loading events',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    eventProvider.error!,
                                    style: Theme.of(context).textTheme.bodySmall,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadEvents,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      final allEvents = eventProvider.events?.items ?? [];
                      // Filter to show only published events (exclude Draft, Archived, Cancelled)
                      final events = allEvents.where((e) => 
                        e.isPublished && !e.isDraft
                      ).toList();

                      // If filters are active, show all matching events in a unified list
                      if (_hasActiveFilters) {
                        if (events.isEmpty) {
                          return SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: AppTheme.textTertiary,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No events found',
                                      style: Theme.of(context).textTheme.headlineSmall,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Try adjusting your filters or search terms',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton.icon(
                                      onPressed: _clearFilters,
                                      icon: const Icon(Icons.clear_all),
                                      label: const Text('Clear all filters'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        // Show filtered events in a horizontal scrollable list
                        return SliverList(
                          delegate: SliverChildListDelegate([
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Found ${events.length} event${events.length == 1 ? '' : 's'}',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                  ),
                                  if (events.isNotEmpty)
                                    TextButton.icon(
                                      onPressed: _clearFilters,
                                      icon: const Icon(Icons.filter_alt_off, size: 18),
                                      label: const Text('Clear'),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 280,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: events.length,
                                itemBuilder: (context, index) {
                                  return EventCard(
                                    event: events[index],
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.eventDetail,
                                        arguments: events[index],
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 32),
                          ]),
                        );
                      }

                      // No filters active - show grouped by category
                      if (events.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.event_busy,
                                    size: 64,
                                    color: AppTheme.textTertiary,
                                  ),
                                  SizedBox(height: 16),
                                  Text('No events available'),
                                  SizedBox(height: 8),
                                  Text(
                                    'Check back later for new events',
                                    style: TextStyle(color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      // Group events by category when no filters are active
                      final cultureEvents = _getEventsByCategory(events, 'Culture');
                      final sportEvents = _getEventsByCategory(events, 'Sport');
                      final musicEvents = _getEventsByCategory(events, 'Music');
                      final filmEvents = _getEventsByCategory(events, 'Film');

                      return SliverList(
                        delegate: SliverChildListDelegate([
                          // Culture Events
                          if (cultureEvents.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Culture events',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 280,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: cultureEvents.length,
                                itemBuilder: (context, index) {
                                  return EventCard(
                                    event: cultureEvents[index],
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.eventDetail,
                                        arguments: cultureEvents[index],
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],

                          // Sport Events
                          if (sportEvents.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Sport events',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 280,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: sportEvents.length,
                                itemBuilder: (context, index) {
                                  return EventCard(
                                    event: sportEvents[index],
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.eventDetail,
                                        arguments: sportEvents[index],
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],

                          // Music Events
                          if (musicEvents.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Music events',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 280,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: musicEvents.length,
                                itemBuilder: (context, index) {
                                  return EventCard(
                                    event: musicEvents[index],
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.eventDetail,
                                        arguments: musicEvents[index],
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],

                          // Film Events
                          if (filmEvents.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Film events',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 280,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: filmEvents.length,
                                itemBuilder: (context, index) {
                                  return EventCard(
                                    event: filmEvents[index],
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.eventDetail,
                                        arguments: filmEvents[index],
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],

                          // Popular Cities (only show when no filters active)
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Popular cities',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: _popularCities.map((city) {
                                final isSelected = _selectedCity == city;
                                return ChoiceChip(
                                  label: Text(city),
                                  selected: isSelected,
                                  onSelected: (_) => _onCitySelected(city),
                                  backgroundColor: AppTheme.backgroundGray,
                                  selectedColor: AppTheme.primaryColor,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ]),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestEventsList() {
    final allEvents = _getTestEvents();
    // Filter to show only published events (exclude Draft)
    final publishedEvents = allEvents.where((e) => e.isPublished && !e.isDraft).toList();
    final cultureEvents = _getEventsByCategory(publishedEvents, 'Culture');
    final sportEvents = _getEventsByCategory(publishedEvents, 'Sport');

    return Column(
      children: [
        // Culture Events
        if (cultureEvents.isNotEmpty) ...[
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Culture events',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: cultureEvents.length,
              itemBuilder: (context, index) {
                return EventCard(
                  event: cultureEvents[index],
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.eventDetail,
                      arguments: cultureEvents[index],
                    );
                  },
                );
              },
            ),
          ),
        ],

        // Sport Events
        if (sportEvents.isNotEmpty) ...[
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Sport events',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: sportEvents.length,
              itemBuilder: (context, index) {
                return EventCard(
                  event: sportEvents[index],
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.eventDetail,
                      arguments: sportEvents[index],
                    );
                  },
                );
              },
            ),
          ),
        ],

        // Popular Cities
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Popular cities',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _popularCities.map((city) {
              final isSelected = _selectedCity == city;
              return ChoiceChip(
                label: Text(city),
                selected: isSelected,
                onSelected: (_) => _onCitySelected(city),
                backgroundColor: AppTheme.backgroundGray,
                selectedColor: AppTheme.primaryColor,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final authProvider = context.read<AuthProvider>();
        final user = authProvider.currentUser;

        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (user != null) ...[
                Text(
                  '${user.firstName} ${user.lastName}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const Divider(height: 32),
              ],
              ListTile(
                leading: const Icon(Icons.confirmation_number_outlined),
                title: const Text('My Tickets'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.tickets);
                },
              ),
              ListTile(
                leading: const Icon(Icons.event_outlined),
                title: const Text('My Events'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.myEvents);
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
