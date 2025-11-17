import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import 'user_detail_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedRoleFilter;
  List<String> _availableRoles = ['User', 'Organizer', 'Scanner', 'Admin'];

  @override
  void initState() {
    super.initState();
    print('🔵 UserManagementScreen: initState called');
    // Učitaj korisnike kada se screen otvori
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        print('🔵 UserManagementScreen: Loading users...');
        final adminProvider = Provider.of<AdminProvider>(context, listen: false);
        adminProvider.loadUsers();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> _getFilteredUsers(List<dynamic> users) {
    var filtered = users;

    // Filtriranje po pretrazi (ime ili prezime)
    if (_searchController.text.isNotEmpty) {
      final searchLower = _searchController.text.toLowerCase();
      filtered = filtered.where((user) {
        final firstName = (user['firstName'] as String? ?? '').toLowerCase();
        final lastName = (user['lastName'] as String? ?? '').toLowerCase();
        final email = (user['email'] as String? ?? '').toLowerCase();
        return firstName.contains(searchLower) ||
            lastName.contains(searchLower) ||
            email.contains(searchLower);
      }).toList();
    }

    // Filtriranje po roli
    if (_selectedRoleFilter != null && _selectedRoleFilter!.isNotEmpty) {
      filtered = filtered.where((user) {
        final roles = user['roles'] as List<dynamic>? ?? [];
        return roles.any((role) => role == _selectedRoleFilter);
      }).toList();
    }

    return filtered;
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Admin':
        return Colors.red;
      case 'Organizer':
        return Colors.blue;
      case 'Scanner':
        return Colors.green;
      case 'User':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRolesCell(List<dynamic> roles) {
    if (roles.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Nema role',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade700,
          ),
        ),
      );
    }

    final roleList = roles.map((r) => r.toString()).toList();
    
    // Ako ima samo jedna rola, prikaži je kompaktno
    if (roleList.length == 1) {
      final role = roleList.first;
      final color = _getRoleColor(role);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              role,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Ako ima više rola, prikaži kompaktno sa popup menu-om
    return PopupMenuButton<String>(
      tooltip: 'Klikni za prikaz svih rola',
      child: Tooltip(
        message: roleList.join(', '),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.badge,
                size: 14,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                '${roleList.length} role',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: Colors.blue.shade700,
              ),
            ],
          ),
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Text(
            'Role korisnika',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const PopupMenuDivider(),
        ...roleList.map((role) {
          final color = _getRoleColor(role);
          return PopupMenuItem<String>(
            enabled: false,
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    print('🔵 UserManagementScreen: build called');
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        print('🔵 UserManagementScreen: Consumer builder called');
        print('🔵 Users count: ${adminProvider.users.length}');
        print('🔵 Is loading: ${adminProvider.isLoadingUsers}');
        print('🔵 Error: ${adminProvider.usersError}');
        
        final users = adminProvider.users;
        final filteredUsers = _getFilteredUsers(users);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header sa search i filter
              Row(
                children: [
                  Expanded(
                    child: StatefulBuilder(
                      builder: (context, setState) => TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Pretraži po imenu, prezimenu ili emailu...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Role filter dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFE0E0E0),
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRoleFilter,
                        hint: const Text('Sve role'),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Sve role'),
                          ),
                          ..._availableRoles.map((role) => DropdownMenuItem<String>(
                                value: role,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _getRoleColor(role),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(role),
                                  ],
                                ),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRoleFilter = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Create User button
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      _showCreateUserDialog(context, adminProvider);
                    },
                    tooltip: 'Kreiraj korisnika',
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Refresh button
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      adminProvider.loadUsers();
                    },
                    tooltip: 'Osvježi listu',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF5F5F5),
                      foregroundColor: const Color(0xFF212121),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stats row
              Row(
                children: [
                  _buildStatChip(
                    context,
                    'Ukupno korisnika',
                    '${users.length}',
                    Icons.people,
                  ),
                  const SizedBox(width: 16),
                  _buildStatChip(
                    context,
                    'Prikazano',
                    '${filteredUsers.length}',
                    Icons.filter_list,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Users table
              Expanded(
                child: adminProvider.isLoadingUsers && users.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : adminProvider.usersError != null && users.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Greška pri učitavanju korisnika',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  adminProvider.usersError!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    adminProvider.loadUsers();
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Pokušaj ponovo'),
                                ),
                              ],
                            ),
                          )
                        : filteredUsers.isEmpty
                            ? Stack(
                                children: [
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search_off,
                                          size: 64,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          users.isEmpty
                                              ? 'Nema korisnika'
                                              : 'Nema rezultata pretrage',
                                          style: Theme.of(context).textTheme.titleLarge,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          users.isEmpty
                                              ? 'Korisnici će biti prikazani kada budu dodani u sistem.'
                                              : 'Pokušaj promijeniti kriterijume pretrage.',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: Colors.grey.shade600,
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Show loading overlay if loading and we have existing users
                                  if (adminProvider.isLoadingUsers && users.isNotEmpty)
                                    Container(
                                      color: Colors.white.withOpacity(0.8),
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                ],
                              )
                            : Stack(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            minWidth: constraints.maxWidth,
                                          ),
                                          child: DataTable(
                                            showCheckboxColumn: false,
                                            columnSpacing: 24,
                                            horizontalMargin: 24,
                                            headingRowHeight: 56,
                                            dataRowMinHeight: 56,
                                            dataRowMaxHeight: 72,
                                            headingRowColor: MaterialStateProperty.all(
                                              Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                                            ),
                                      columns: const [
                                        DataColumn(
                                          label: Text(
                                            'Ime',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Prezime',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Email',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Role',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Email potvrđen',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Datum registracije',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Akcije',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                      rows: filteredUsers.map((user) {
                                        final roles = user['roles'] as List<dynamic>? ?? [];
                                        final createdAt = user['createdAt'] != null
                                            ? DateTime.parse(user['createdAt'] as String)
                                            : null;
                                        final dateFormat = DateFormat('dd.MM.yyyy');

                                        return DataRow(
                                          onSelectChanged: (selected) {
                                            if (selected == true) {
                                              final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                              final isOwnProfile = authProvider.currentUser?.id == user['id'];
                                              
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) => UserDetailScreen(
                                                    user: user,
                                                    isOwnProfile: isOwnProfile,
                                                  ),
                                                ),
                                              ).then((_) async {
                                                // Refresh user list when returning from detail screen
                                                // Add small delay to ensure any updates from UserDetailScreen are complete
                                                await Future.delayed(const Duration(milliseconds: 100));
                                                await adminProvider.loadUsers();
                                              });
                                            }
                                          },
                                          cells: [
                                            DataCell(
                                              Text(
                                                user['firstName'] as String? ?? '-',
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                user['lastName'] as String? ?? '-',
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                user['email'] as String? ?? '-',
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                            ),
                                            DataCell(
                                              _buildRolesCell(roles),
                                            ),
                                            DataCell(
                                              Icon(
                                                user['emailConfirmed'] == true
                                                    ? Icons.check_circle
                                                    : Icons.cancel,
                                                color: user['emailConfirmed'] == true
                                                    ? Colors.green
                                                    : Colors.red,
                                                size: 20,
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                createdAt != null
                                                    ? dateFormat.format(createdAt)
                                                    : '-',
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                            ),
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.edit, size: 20),
                                                    onPressed: () {
                                                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                                      final isOwnProfile = authProvider.currentUser?.id == user['id'];
                                                      
                                                      Navigator.of(context).push(
                                                        MaterialPageRoute(
                                                          builder: (context) => UserDetailScreen(
                                                            user: user,
                                                            initialEditMode: true,
                                                            isOwnProfile: isOwnProfile,
                                                          ),
                                                        ),
                                                      ).then((_) async {
                                                        // Refresh user list when returning from detail screen
                                                        print('🔵 UserManagement: Returned from UserDetailScreen, refreshing...');
                                                        await Future.delayed(const Duration(milliseconds: 100)); // Small delay to ensure state is settled
                                                        await adminProvider.loadUsers();
                                                        print('✅ UserManagement: User list refreshed');
                                                      });
                                                    },
                                                    tooltip: 'Uredi korisnika',
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete, size: 20),
                                                    color: Colors.red,
                                                    onPressed: () {
                                                      _showDeleteUserConfirmation(context, adminProvider, user);
                                                    },
                                                    tooltip: 'Obriši korisnika',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                  ),
                                  // Show loading overlay if loading and we have existing users
                                  if (adminProvider.isLoadingUsers && users.isNotEmpty)
                                    Positioned.fill(
                                      child: Container(
                                        color: Colors.white.withOpacity(0.8),
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatChip(BuildContext context, String label, String value, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
    );
  }

  void _showCreateUserDialog(BuildContext context, AdminProvider adminProvider) {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    String? selectedRole;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Kreiraj novog korisnika'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'Ime *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ime je obavezno';
                      }
                      if (value.length > 50) {
                        return 'Ime ne može biti duže od 50 karaktera';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Prezime *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Prezime je obavezno';
                      }
                      if (value.length > 50) {
                        return 'Prezime ne može biti duže od 50 karaktera';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email je obavezan';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Neispravna email adresa';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Lozinka *',
                      border: OutlineInputBorder(),
                      helperText: 'Minimum 12 karaktera',
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lozinka je obavezna';
                      }
                      if (value.length < 12) {
                        return 'Lozinka mora imati najmanje 12 karaktera';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Rola',
                      border: OutlineInputBorder(),
                      helperText: 'Ostavite prazno za User (default)',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('User (default)'),
                      ),
                      ..._availableRoles.map((role) => DropdownMenuItem<String>(
                            value: role,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _getRoleColor(role),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(role),
                              ],
                            ),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Otkaži'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  // Ako nije odabrana rola, koristi "User" kao default
                  final roleToAssign = selectedRole ?? 'User';
                  
                  final success = await adminProvider.createUser(
                    email: emailController.text.trim(),
                    password: passwordController.text,
                    firstName: firstNameController.text.trim(),
                    lastName: lastNameController.text.trim(),
                    roleName: roleToAssign,
                  );

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Korisnik je uspješno kreiran'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      // Koristi createUserError umjesto usersError da ne bi sakrilo tabelu
                      final errorMessage = adminProvider.createUserError ?? 'Greška pri kreiranju korisnika';
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(errorMessage),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Kreiraj'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, AdminProvider adminProvider, Map<String, dynamic> user) {
    final formKey = GlobalKey<FormState>();
    final firstNameController = TextEditingController(text: user['firstName'] as String? ?? '');
    final lastNameController = TextEditingController(text: user['lastName'] as String? ?? '');
    final emailController = TextEditingController(text: user['email'] as String? ?? '');
    bool emailConfirmed = user['emailConfirmed'] == true;
    // Provjeri oba slučaja - camelCase i PascalCase
    final userId = (user['id'] ?? user['Id']) as String? ?? '';
    
    // Učitaj trenutne role korisnika
    final initialRoles = (user['roles'] as List<dynamic>? ?? [])
        .map((r) => r.toString())
        .toList();

    // Koristi mutable set za praćenje rola
    final currentRoles = Set<String>.from(initialRoles);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Uredi korisnika'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'Ime',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty && value.length > 50) {
                        return 'Ime ne može biti duže od 50 karaktera';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Prezime',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty && value.length > 50) {
                        return 'Prezime ne može biti duže od 50 karaktera';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Neispravna email adresa';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Email potvrđen'),
                    value: emailConfirmed,
                    onChanged: (value) {
                      setState(() {
                        emailConfirmed = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 24),
                  // Role management section
                  Text(
                    'Role',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ..._availableRoles.map((role) {
                    final hasRole = currentRoles.contains(role);
                    return Builder(
                      builder: (context) {
                        return CheckboxListTile(
                          title: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getRoleColor(role),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(role),
                            ],
                          ),
                          value: hasRole,
                          onChanged: (value) async {
                            if (value == true && !hasRole) {
                              // Dodaj rolu
                              final success = await adminProvider.addUserToRole(userId, role);
                              if (context.mounted) {
                                if (success) {
                                  setState(() {
                                    currentRoles.add(role);
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Rola $role je dodana korisniku'),
                                      backgroundColor: Colors.green,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        adminProvider.usersError ?? 'Greška pri dodavanju role',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            } else if (value == false && hasRole) {
                              // Ukloni rolu
                              final success = await adminProvider.removeUserFromRole(userId, role);
                              if (context.mounted) {
                                if (success) {
                                  setState(() {
                                    currentRoles.remove(role);
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Rola $role je uklonjena od korisnika'),
                                      backgroundColor: Colors.green,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        adminProvider.usersError ?? 'Greška pri uklanjanju role',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Otkaži'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final success = await adminProvider.updateUser(
                    userId: userId,
                    firstName: firstNameController.text.trim().isNotEmpty 
                        ? firstNameController.text.trim() 
                        : null,
                    lastName: lastNameController.text.trim().isNotEmpty 
                        ? lastNameController.text.trim() 
                        : null,
                    email: emailController.text.trim().isNotEmpty 
                        ? emailController.text.trim() 
                        : null,
                    emailConfirmed: emailConfirmed,
                  );

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    if (success) {
                      // Check if the updated user is the currently logged-in user
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      if (authProvider.currentUser?.id == userId) {
                        print('🔵 UserManagement: Updated user is currently logged in, refreshing AuthProvider...');
                        await authProvider.refreshCurrentUser();
                        print('✅ UserManagement: AuthProvider refreshed for logged-in user');
                      }
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Korisnik je uspješno ažuriran'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            adminProvider.usersError ?? 'Greška pri ažuriranju korisnika',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Sačuvaj'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteUserConfirmation(BuildContext context, AdminProvider adminProvider, Map<String, dynamic> user) {
    // Provjeri oba slučaja - camelCase i PascalCase
    final userId = (user['id'] ?? user['Id']) as String? ?? '';
    final userEmail = user['email'] as String? ?? 'Nepoznat korisnik';
    final userName = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    final displayName = userName.isNotEmpty ? userName : userEmail;

    // Provjeri da li korisnik pokušava obrisati samog sebe
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final isCurrentUser = currentUser?.id == userId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Potvrda brisanja'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCurrentUser)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ne možete obrisati vlastiti nalog!',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              isCurrentUser
                  ? 'Ne možete obrisati vlastiti nalog. Ova akcija nije dozvoljena.'
                  : 'Da li ste sigurni da želite obrisati korisnika?',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (!isCurrentUser) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Korisnik:',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ova akcija je nepovratna. Svi podaci korisnika će biti trajno obrisani.',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Otkaži'),
          ),
          if (!isCurrentUser)
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                // Prikaži loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                final success = await adminProvider.deleteUser(userId);

                if (context.mounted) {
                  Navigator.of(context).pop(); // Zatvori loading dialog
                  
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Korisnik $displayName je uspješno obrisan'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          adminProvider.usersError ?? 'Greška pri brisanju korisnika',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Obriši'),
            ),
        ],
      ),
    );
  }
}
