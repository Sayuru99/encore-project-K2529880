import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/validators.dart' as v;
import '../../data/event.dart';
import '../../state/providers.dart';
import '../widgets/star_rating.dart';

/// Create when [existing] is null, otherwise edit.
class EventFormScreen extends ConsumerStatefulWidget {
  const EventFormScreen({super.key, this.existing, this.defaultStatus = 'planned'});
  final EventItem? existing;
  final String defaultStatus;

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _artist = TextEditingController(text: widget.existing?.artist);
  late final _venue = TextEditingController(text: widget.existing?.venue);
  late final _price = TextEditingController(
      text: widget.existing == null || widget.existing!.price == 0 ? '' : widget.existing!.price.toStringAsFixed(0));
  late final _notes = TextEditingController(text: widget.existing?.notes);
  late DateTime _date = widget.existing?.date ?? DateTime.now().add(const Duration(days: 7)).copyWith(hour: 19, minute: 0);
  late String _type = widget.existing?.type ?? 'concert';
  late String _status = widget.existing?.status ?? widget.defaultStatus;
  late int _rating = widget.existing?.rating ?? 0;
  String? _dateError;

  @override
  void dispose() {
    for (final c in [_title, _artist, _venue, _price, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final day = await showDatePicker(
        context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (day == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_date));
    setState(() => _date = DateTime(day.year, day.month, day.day, time?.hour ?? _date.hour, time?.minute ?? _date.minute));
  }

  Future<void> _save() async {
    setState(() => _dateError = v.attendedDate(_status, _date));
    if (!_form.currentState!.validate() || _dateError != null) return;
    final event = EventItem(
      id: widget.existing?.id ?? const Uuid().v4(),
      title: _title.text.trim(),
      artist: _artist.text.trim(),
      venue: _venue.text.trim(),
      date: _date,
      type: _type,
      status: _status,
      price: double.tryParse(_price.text.trim()) ?? 0,
      rating: _status == 'attended' ? _rating : 0,
      notes: _notes.text.trim(),
      image: widget.existing?.image ?? '',
      updatedAt: DateTime.now(),
    );
    await ref.read(eventsProvider.notifier).save(event, isNew: widget.existing == null);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 16);
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'New event' : 'Edit event')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'planned', label: Text('Planning to go'), icon: Icon(Icons.event)),
              ButtonSegment(value: 'attended', label: Text('I went'), icon: Icon(Icons.check)),
            ],
            selected: {_status},
            onSelectionChanged: (s) => setState(() => _status = s.first),
          ),
          gap,
          TextFormField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Event name *', hintText: 'e.g. Colombo Jazz Night'),
            textCapitalization: TextCapitalization.words,
            validator: (s) => v.requiredText(s, field: 'Event name'),
          ),
          gap,
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Type'),
            items: [
              for (final t in eventTypes)
                DropdownMenuItem(value: t, child: Row(children: [Icon(typeIcons[t], size: 20), const SizedBox(width: 8), Text(t)])),
            ],
            onChanged: (t) => setState(() => _type = t!),
          ),
          gap,
          TextFormField(
            controller: _artist,
            decoration: const InputDecoration(labelText: 'Artist, team or cast'),
            textCapitalization: TextCapitalization.words,
            validator: (s) => (s ?? '').length > 100 ? 'Keep it under 100 characters' : null,
          ),
          gap,
          TextFormField(
            controller: _venue,
            decoration: const InputDecoration(labelText: 'Venue', prefixIcon: Icon(Icons.place)),
            textCapitalization: TextCapitalization.words,
            validator: (s) => (s ?? '').length > 100 ? 'Keep it under 100 characters' : null,
          ),
          gap,
          InputDecorator(
            decoration: InputDecoration(labelText: 'Date and time', errorText: _dateError, prefixIcon: const Icon(Icons.schedule)),
            child: InkWell(
              onTap: _pickDate,
              child: Text(DateFormat('EEE d MMM y, h:mm a').format(_date)),
            ),
          ),
          gap,
          TextFormField(
            controller: _price,
            decoration: const InputDecoration(labelText: 'Ticket price (LKR)', hintText: 'Leave empty if free', prefixIcon: Icon(Icons.payments)),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: v.price,
          ),
          if (_status == 'attended') ...[
            gap,
            Text('How was it?', style: Theme.of(context).textTheme.titleMedium),
            StarRating(value: _rating, onChanged: (r) => setState(() => _rating = r)),
          ],
          gap,
          TextFormField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'Notes', hintText: 'Who you went with, best moment, setlist...'),
            maxLines: 4,
            maxLength: 500,
          ),
          gap,
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Save')),
        ]),
      ),
    );
  }
}
