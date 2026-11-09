import 'package:flutter/material.dart';

import 'controller.dart';
import 'models.dart';
import 'ui.dart';

Future<void> showWorkoutForm(
  BuildContext context, {
  Workout? workout,
  ActivityType? type,
}) => showDialog<void>(
  context: context,
  builder: (_) => WorkoutForm(workout: workout, type: type),
);

class WorkoutForm extends StatefulWidget {
  const WorkoutForm({super.key, this.workout, this.type});
  final Workout? workout;
  final ActivityType? type;
  @override
  State<WorkoutForm> createState() => _WorkoutFormState();
}

class _WorkoutFormState extends State<WorkoutForm> {
  final form = GlobalKey<FormState>();
  late final TextEditingController title,
      minutes,
      calories,
      distance,
      steps,
      notes;
  late ActivityType type;
  late DateTime date;
  late final String workoutId;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    final workout = widget.workout;
    workoutId =
        workout?.id ?? 'manual-${DateTime.now().microsecondsSinceEpoch}';
    type = workout?.type ?? widget.type ?? ActivityType.strength;
    date = workout?.date ?? DateTime.now();
    title = TextEditingController(
      text: workout?.title ?? 'My ${type.label.toLowerCase()} workout',
    );
    minutes = TextEditingController(text: workout?.minutes.toString() ?? '30');
    calories = TextEditingController(text: workout?.calories.toString() ?? '');
    distance = TextEditingController(text: workout?.distance.toString() ?? '');
    steps = TextEditingController(text: workout?.steps.toString() ?? '');
    notes = TextEditingController(text: workout?.notes ?? '');
  }

  @override
  void dispose() {
    for (final field in [title, minutes, calories, distance, steps, notes]) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) {
      return;
    }
    setState(() => busy = true);
    final controller = FitnessScope.of(context);
    final enteredMinutes = int.parse(minutes.text.trim());
    final duration =
        widget.workout != null && enteredMinutes == widget.workout!.minutes
        ? widget.workout!.seconds
        : enteredMinutes * 60;
    final workout = Workout(
      id: workoutId,
      title: title.text.trim(),
      type: type,
      date: date,
      seconds: duration,
      calories: calories.text.trim().isEmpty
          ? (type.met * 3.5 * controller.currentWeight / 200 * duration / 60)
                .round()
                .clamp(0, 20000)
          : int.parse(calories.text.trim()),
      distance: double.tryParse(distance.text.trim()) ?? 0,
      steps: int.tryParse(steps.text.trim()) ?? 0,
      notes: notes.text.trim(),
    );
    final ok = await runAction(
      context,
      () => controller.data.workouts.any((w) => w.id == workoutId)
          ? controller.updateWorkout(workout)
          : controller.addWorkout(workout),
    );
    if (!mounted) {
      return;
    }
    if (ok) {
      Navigator.pop(context);
      toast(
        context,
        widget.workout == null
            ? 'Activity logged. Every effort counts!'
            : 'Activity updated.',
      );
    } else {
      setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 540,
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: form,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.workout == null
                          ? 'Log an activity'
                          : 'Edit activity',
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: busy ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Text(
                'Big effort or small steps. It all adds up.',
                style: TextStyle(color: Palette.muted(context), fontSize: 12),
              ),
              const SizedBox(height: 26),
              TextFormField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Activity name'),
                maxLength: 80,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Give your activity a name'
                    : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<ActivityType>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Activity type'),
                items: ActivityType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(type.icon, size: 18, color: type.color),
                            const SizedBox(width: 12),
                            Text(type.label),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: busy
                    ? null
                    : (value) => setState(() => type = value!),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : () async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate: dateOnly(date),
                          firstDate: DateTime(2000),
                          lastDate: dateOnly(DateTime.now()),
                        );
                        if (selected != null && mounted) {
                          setState(
                            () => date = DateTime(
                              selected.year,
                              selected.month,
                              selected.day,
                              date.hour,
                              date.minute,
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text(longDate(date)),
              ),
              const SizedBox(height: 18),
              FormPair(
                left: TextFormField(
                  controller: minutes,
                  decoration: const InputDecoration(
                    labelText: 'Duration',
                    suffixText: 'min',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => validateNumber(v, 1, 1440, integer: true),
                ),
                right: TextFormField(
                  controller: calories,
                  decoration: const InputDecoration(
                    labelText: 'Calories (optional)',
                    suffixText: 'kcal',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? null
                      : validateNumber(v, 0, 20000, integer: true),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 18),
                child: Text(
                  'Blank calories are estimated from duration, activity, and your weight.',
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.5,
                    color: Palette.muted(context),
                  ),
                ),
              ),
              FormPair(
                left: TextFormField(
                  controller: distance,
                  decoration: const InputDecoration(
                    labelText: 'Distance (optional)',
                    suffixText: 'km',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? null
                      : validateNumber(v, 0, 1000),
                ),
                right: TextFormField(
                  controller: steps,
                  decoration: const InputDecoration(
                    labelText: 'Steps (optional)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? null
                      : validateNumber(v, 0, 200000, integer: true),
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: notes,
                maxLines: 3,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'How did it feel? (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: busy ? null : submit,
                icon: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  busy
                      ? 'Saving…'
                      : widget.workout == null
                      ? 'Save activity'
                      : 'Save changes',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class FormPair extends StatelessWidget {
  const FormPair({super.key, required this.left, required this.right});
  final Widget left, right;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => constraints.maxWidth < 350
        ? Column(children: [left, const SizedBox(height: 18), right])
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: 16),
              Expanded(child: right),
            ],
          ),
  );
}

Future<void> showWeightForm(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const _WeightForm());

class _WeightForm extends StatefulWidget {
  const _WeightForm();
  @override
  State<_WeightForm> createState() => _WeightFormState();
}

class _WeightFormState extends State<_WeightForm> {
  final form = GlobalKey<FormState>();
  final weight = TextEditingController();
  DateTime date = dateOnly(DateTime.now());
  bool busy = false;
  @override
  void dispose() {
    weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text(
      'A little check-in',
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
    ),
    content: SizedBox(
      width: 350,
      child: Form(
        key: form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Progress is a trend, not a single number.',
              style: TextStyle(fontSize: 12, color: Palette.muted(context)),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: weight,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Weight',
                suffixText: 'kg',
              ),
              validator: (v) => validateNumber(v, 20, 400),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: busy
                  ? null
                  : () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2000),
                        lastDate: dateOnly(DateTime.now()),
                      );
                      if (selected != null && mounted) {
                        setState(() => date = selected);
                      }
                    },
              icon: const Icon(Icons.calendar_today_outlined, size: 16),
              label: Text(longDate(date)),
            ),
            const SizedBox(height: 10),
            Text(
              'A new entry replaces any weight logged on the same date.',
              style: TextStyle(
                fontSize: 10,
                height: 1.6,
                color: Palette.muted(context),
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: busy
            ? null
            : () async {
                if (!form.currentState!.validate()) {
                  return;
                }
                setState(() => busy = true);
                final controller = FitnessScope.of(context);
                final ok = await runAction(
                  context,
                  () => controller.addWeight(
                    date,
                    double.parse(weight.text.trim()),
                  ),
                );
                if (context.mounted && ok) {
                  Navigator.pop(context);
                  toast(
                    context,
                    'Weight logged. Keep showing up for yourself.',
                  );
                } else if (mounted) {
                  setState(() => busy = false);
                }
              },
        child: Text(busy ? 'Saving…' : 'Log weight'),
      ),
    ],
  );
}

Future<void> showWorkoutDetails(BuildContext context, Workout workout) async {
  final controller = FitnessScope.of(context);
  final action = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          IconTile(workout.type.icon, color: workout.type.color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              workout.title,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 390,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Tag(workout.type.label, color: workout.type.color),
              const SizedBox(height: 16),
              Text(
                longDate(workout.date),
                style: TextStyle(color: Palette.muted(context), fontSize: 12),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 24,
                runSpacing: 16,
                children: [
                  Text('${workout.minutes} min'),
                  Text('${number(workout.calories)} kcal'),
                  if (workout.distance > 0)
                    Text('${workout.distance.toStringAsFixed(1)} km'),
                  if (workout.steps > 0) Text('${number(workout.steps)} steps'),
                ],
              ),
              if (workout.notes.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Your notes',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  workout.notes,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.7,
                    color: Palette.muted(context),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 'delete'),
          child: const Text(
            'Delete',
            style: TextStyle(color: Color(0xFFC14959)),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, 'edit'),
          child: const Text('Edit'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    ),
  );
  if (!context.mounted) {
    return;
  }
  if (action == 'edit') {
    await showWorkoutForm(context, workout: workout);
    return;
  }
  if (action == 'delete' &&
      await confirm(
        context,
        title: 'Delete this activity?',
        message:
            '“${workout.title}” will be removed from your history and progress totals.',
        label: 'Delete activity',
        destructive: true,
      )) {
    if (context.mounted) {
      await runAction(
        context,
        () => controller.deleteWorkout(workout.id),
        success: 'Activity deleted.',
      );
    }
  }
}
