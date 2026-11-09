import 'package:flutter/material.dart';

import 'controller.dart';
import 'dialogs.dart';
import 'models.dart';
import 'ui.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String query = '';
  ActivityType? type;
  int period = 0;
  final search = TextEditingController();
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = FitnessScope.of(context);
    final cutoff = dateOnly(controller.clock())
        .subtract(Duration(days: period - 1));
    final filtered = controller.sortedWorkouts
        .where(
          (w) =>
              (type == null || w.type == type) &&
              (period == 0 || !dateOnly(w.date).isBefore(cutoff)) &&
              ('${w.title} ${w.type.label} ${w.notes}'.toLowerCase().contains(
                query.toLowerCase(),
              )),
        )
        .toList();
    final groups = <String, List<Workout>>{};
    for (final workout in filtered) {
      groups.putIfAbsent(dayKey(workout.date), () => []).add(workout);
    }
    final minutes = filtered.fold(0, (sum, w) => sum + w.minutes);
    final calories = filtered.fold(0, (sum, w) => sum + w.calories);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageTitle(
          title: 'Every effort has a story.',
          subtitle: 'Your movement, your milestones, all in one place.',
          eyebrow: 'ACTIVITY HISTORY',
          action: FilledButton.icon(
            onPressed: () => showWorkoutForm(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Log activity'),
          ),
        ),
        const SizedBox(height: 26),
        ResponsiveGrid(
          minWidth: 160,
          maxColumns: 3,
          children: [
            _HistoryStat(
              'Activities',
              '${filtered.length}',
              Icons.fitness_center_rounded,
              Palette.primary,
            ),
            _HistoryStat(
              'Time well spent',
              '$minutes min',
              Icons.timer_outlined,
              const Color(0xFF3F9B79),
            ),
            _HistoryStat(
              'Energy burned',
              '${number(calories)} kcal',
              Icons.local_fire_department_outlined,
              Palette.orange,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final filters = Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 155,
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: type?.name ?? 'all',
                          decoration: const InputDecoration(
                            labelText: 'Activity',
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: 'all',
                              child: Text(
                                'All activities',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            ...ActivityType.values.map(
                              (t) => DropdownMenuItem(
                                value: t.name,
                                child: Text(
                                  t.label,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(
                            () => type = v == 'all'
                                ? null
                                : ActivityType.values.byName(v!),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 155,
                        child: DropdownButtonFormField<int>(
                          isExpanded: true,
                          initialValue: period,
                          decoration: const InputDecoration(
                            labelText: 'Date range',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 0,
                              child: Text(
                                'All time',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 7,
                              child: Text(
                                'Last 7 days',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 28,
                              child: Text(
                                'Last 28 days',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => period = v!),
                        ),
                      ),
                    ],
                  );
                  final field = TextField(
                    controller: search,
                    onChanged: (v) => setState(() => query = v),
                    decoration: InputDecoration(
                      hintText: 'Find an activity…',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                search.clear();
                                setState(() => query = '');
                              },
                              icon: const Icon(Icons.close_rounded, size: 17),
                            ),
                    ),
                  );
                  return constraints.maxWidth < 720
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            field,
                            const SizedBox(height: 16),
                            filters,
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: field),
                            const SizedBox(width: 16),
                            filters,
                          ],
                        );
                },
              ),
              const SizedBox(height: 24),
              if (filtered.isEmpty)
                EmptyState(
                  icon: Icons.manage_search_rounded,
                  title: controller.data.workouts.isEmpty
                      ? 'Make your first move'
                      : 'No matching activities',
                  message: controller.data.workouts.isEmpty
                      ? 'Log a workout to begin your activity story.'
                      : 'Try another search or broaden your filters.',
                  action: controller.data.workouts.isEmpty
                      ? OutlinedButton(
                          onPressed: () => showWorkoutForm(context),
                          child: const Text('Log an activity'),
                        )
                      : null,
                )
              else
                ...groups.entries.map(
                  (entry) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          sameDay(entry.value.first.date, controller.clock())
                              ? 'TODAY'
                              : longDate(entry.value.first.date).toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 1.3,
                            fontWeight: FontWeight.w800,
                            color: Palette.muted(context),
                          ),
                        ),
                      ),
                      ...entry.value.map((w) => WorkoutRow(workout: w)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryStat extends StatelessWidget {
  const _HistoryStat(this.label, this.value, this.icon, this.color);
  final String label, value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Surface(
    padding: const EdgeInsets.all(20),
    child: Row(
      children: [
        IconTile(icon, color: color),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10, color: Palette.muted(context)),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class WorkoutRow extends StatelessWidget {
  const WorkoutRow({super.key, required this.workout});
  final Workout workout;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => showWorkoutDetails(context, workout),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 500;
            return Row(
              children: [
                IconTile(
                  workout.type.icon,
                  color: workout.type.color,
                  size: 42,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        compact
                            ? '${shortDate(workout.date)} · ${workout.minutes} min · ${workout.calories} kcal'
                            : '${workout.type.label} · ${shortDate(workout.date)}',
                        style: TextStyle(
                          fontSize: 9,
                          color: Palette.muted(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 65,
                    child: Text(
                      '${workout.minutes} min',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 75,
                    child: Text(
                      '${workout.calories} kcal',
                      style: TextStyle(
                        fontSize: 10,
                        color: Palette.muted(context),
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 17,
                  color: Palette.muted(context),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
