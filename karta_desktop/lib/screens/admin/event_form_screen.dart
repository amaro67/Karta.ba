import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/event_provider.dart';
import '../../model/event/event_dto.dart';
import '../../utils/base_textfield.dart';
import '../../utils/error_dialog.dart';

class EventFormScreen extends StatefulWidget {
  final EventDto? event;

  const EventFormScreen({super.key, this.event});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _venueController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _categoryController = TextEditingController();
  final _tagsController = TextEditingController();
  final _coverImageUrlController = TextEditingController();

  DateTime? _startsAt;
  DateTime? _endsAt;
  String _status = 'Draft';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _populateForm(widget.event!);
    } else {
      _countryController.text = 'Bosnia and Herzegovina';
    }
  }

  void _populateForm(EventDto event) {
    _titleController.text = event.title;
    _descriptionController.text = event.description ?? '';
    _venueController.text = event.venue;
    _cityController.text = event.city;
    _countryController.text = event.country;
    _categoryController.text = event.category;
    _tagsController.text = event.tags ?? '';
    _coverImageUrlController.text = event.coverImageUrl ?? '';
    _startsAt = event.startsAt;
    _endsAt = event.endsAt;
    // Ensure status is valid, default to Draft if not
    final validStatuses = ['Draft', 'Published', 'Cancelled', 'Archived'];
    _status = validStatuses.contains(event.status) ? event.status : 'Draft';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    _coverImageUrlController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(
    BuildContext context,
    bool isStartDate,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _startsAt : _endsAt) ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          (isStartDate ? _startsAt : _endsAt) ?? DateTime.now(),
        ),
      );
      if (time != null) {
        setState(() {
          final dateTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
          if (isStartDate) {
            _startsAt = dateTime;
            if (_endsAt != null && _endsAt!.isBefore(_startsAt!)) {
              _endsAt = null;
            }
          } else {
            _endsAt = dateTime;
          }
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startsAt == null) {
      ErrorDialog.show(
        context,
        title: 'Validation Error',
        message: 'Please select a start date and time',
      );
      return;
    }

    setState(() => _isLoading = true);

    final eventData = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      'venue': _venueController.text.trim(),
      'city': _cityController.text.trim(),
      'country': _countryController.text.trim(),
      'startsAt': _startsAt!.toIso8601String(),
      'endsAt': _endsAt?.toIso8601String(),
      'category': _categoryController.text.trim(),
      'tags': _tagsController.text.trim().isEmpty
          ? null
          : _tagsController.text.trim(),
      'coverImageUrl': _coverImageUrlController.text.trim().isEmpty
          ? null
          : _coverImageUrlController.text.trim(),
      if (widget.event != null) 'status': _status,
    };

    final eventProvider = context.read<EventProvider>();
    final success = widget.event == null
        ? await eventProvider.createEvent(eventData)
        : await eventProvider.updateEvent(widget.event!.id, eventData);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.event == null
                  ? 'Event created successfully'
                  : 'Event updated successfully',
            ),
          ),
        );
      } else {
        ErrorDialog.show(
          context,
          title: 'Error',
          message: eventProvider.error ?? 'Failed to save event',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? 'Create Event' : 'Edit Event'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            BaseTextField(
              key: const ValueKey('title_field'),
              label: 'Title *',
              hint: 'Enter event title',
              controller: _titleController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                if (value.length > 200) {
                  return 'Title must be less than 200 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            BaseTextField(
              key: const ValueKey('description_field'),
              label: 'Description',
              hint: 'Enter event description',
              controller: _descriptionController,
              maxLines: 5,
              maxLength: 2000,
            ),
            const SizedBox(height: 16),
            BaseTextField(
              key: const ValueKey('venue_field'),
              label: 'Venue *',
              hint: 'Enter venue name',
              controller: _venueController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Venue is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: BaseTextField(
                    key: const ValueKey('city_field'),
                    label: 'City *',
                    hint: 'Enter city',
                    controller: _cityController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'City is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: BaseTextField(
                    key: const ValueKey('country_field'),
                    label: 'Country *',
                    hint: 'Enter country',
                    controller: _countryController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Country is required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            BaseTextField(
              key: const ValueKey('category_field'),
              label: 'Category *',
              hint: 'Enter category (e.g., Music, Sports, Theater)',
              controller: _categoryController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Category is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            BaseTextField(
              key: const ValueKey('tags_field'),
              label: 'Tags',
              hint: 'Comma-separated tags',
              controller: _tagsController,
            ),
            const SizedBox(height: 16),
            BaseTextField(
              key: const ValueKey('cover_image_field'),
              label: 'Cover Image URL',
              hint: 'Enter image URL',
              controller: _coverImageUrlController,
            ),
            const SizedBox(height: 16),
            // Date pickers
            Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Date & Time *',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectDate(context, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: Theme.of(context).colorScheme.surface,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _startsAt != null
                                      ? DateFormat('MMM dd, yyyy HH:mm')
                                          .format(_startsAt!)
                                      : 'Select start date',
                                  style: TextStyle(
                                    color: _startsAt != null
                                        ? Theme.of(context).colorScheme.onSurface
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'End Date & Time',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectDate(context, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: Theme.of(context).colorScheme.surface,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _endsAt != null
                                      ? DateFormat('MMM dd, yyyy HH:mm')
                                          .format(_endsAt!)
                                      : 'Select end date (optional)',
                                  style: TextStyle(
                                    color: _endsAt != null
                                        ? Theme.of(context).colorScheme.onSurface
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.event != null) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'Draft', child: Text('Draft')),
                  DropdownMenuItem(value: 'Published', child: Text('Published')),
                  DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                  DropdownMenuItem(value: 'Archived', child: Text('Archived')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _status = value);
                  }
                },
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.event == null ? 'Create Event' : 'Update Event'),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}

