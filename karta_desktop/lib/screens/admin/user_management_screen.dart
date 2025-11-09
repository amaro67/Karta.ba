import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_provider.dart';

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
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header sa search i filter
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Pretraži po imenu, prezimenu ili emailu...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Role filter dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).colorScheme.surface,
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
                  const SizedBox(width: 16),
                  // Create User button
                  ElevatedButton.icon(
                    onPressed: () {
                      _showCreateUserDialog(context, adminProvider);
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Kreiraj korisnika'),
                  ),
                  const SizedBox(width: 8),
                  // Refresh button
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      adminProvider.loadUsers();
                    },
                    tooltip: 'Osvježi listu',
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
                child: adminProvider.isLoadingUsers
                    ? const Center(child: CircularProgressIndicator())
                    : adminProvider.usersError != null
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
                            ? Center(
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
                              )
                            : Card(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columnSpacing: 24,
                                    headingRowColor: MaterialStateProperty.all(
                                      Theme.of(context).colorScheme.surfaceVariant,
                                    ),
                                    columns: const [
                                      DataColumn(
                                        label: Text(
                                          'Ime',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Prezime',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Email',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Role',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Email potvrđen',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Datum registracije',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Akcije',
                                          style: TextStyle(fontWeight: FontWeight.bold),
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
                                        cells: [
                                          DataCell(
                                            Text(user['firstName'] as String? ?? '-'),
                                          ),
                                          DataCell(
                                            Text(user['lastName'] as String? ?? '-'),
                                          ),
                                          DataCell(
                                            Text(user['email'] as String? ?? '-'),
                                          ),
                                          DataCell(
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              children: roles.isEmpty
                                                  ? [
                                                      Chip(
                                                        label: const Text('Nema role'),
                                                        backgroundColor: Colors.grey.shade200,
                                                        labelStyle: const TextStyle(fontSize: 12),
                                                      ),
                                                    ]
                                                  : roles.map<Widget>((role) {
                                                      final roleString = role.toString();
                                                      return Chip(
                                                        label: Text(
                                                          roleString,
                                                          style: const TextStyle(fontSize: 12),
                                                        ),
                                                        backgroundColor:
                                                            _getRoleColor(roleString)
                                                                .withOpacity(0.2),
                                                        labelStyle: TextStyle(
                                                          color: _getRoleColor(roleString),
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      );
                                                    }).toList(),
                                            ),
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
                                            ),
                                          ),
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit, size: 20),
                                                  onPressed: () {
                                                    // TODO: Implement edit user
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Edit korisnika ${user['email']} - Coming soon',
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  tooltip: 'Uredi korisnika',
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, size: 20),
                                                  color: Colors.red,
                                                  onPressed: () {
                                                    // TODO: Implement delete user
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Brisanje korisnika ${user['email']} - Coming soon',
                                                        ),
                                                      ),
                                                    );
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
                  final success = await adminProvider.createUser(
                    email: emailController.text.trim(),
                    password: passwordController.text,
                    firstName: firstNameController.text.trim(),
                    lastName: lastNameController.text.trim(),
                    roleName: selectedRole,
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            adminProvider.usersError ?? 'Greška pri kreiranju korisnika',
                          ),
                          backgroundColor: Colors.red,
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
}
