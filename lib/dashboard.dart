import 'package:flutter/material.dart';

import 'controller.dart';
import 'dialogs.dart';
import 'history.dart';
import 'models.dart';
import 'ui.dart';
import 'workouts.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int days = 7;
  @override
  Widget build(BuildContext context) {
    final controller = FitnessScope.of(context);
    final goals = controller.data.goalLevel;
    final recent = controller.sortedWorkouts.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageTitle(
          title: 'Let’s make today count.',
          subtitle: 'A little movement. A little progress. A healthier you.',
          eyebrow: 'YOUR DAILY DOSE OF MOMENTUM',
          action: FilledButton.icon(
            onPressed: () => showWorkoutForm(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Log activity'),
          ),
        ),
        const SizedBox(height: 26),
        TwoColumn(
          breakpoint: 820,
          left: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6C59ED), Color(0xFF5141C4)],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -25,
                  top: -10,
                  bottom: -10,
                  width: 260,
                  child: Opacity(
                    opacity: MediaQuery.sizeOf(context).width < 600 ? 0.25 : 1,
                    child: const OrbitArt(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              size: 13,
                              color: Palette.mint,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'SHOW UP FOR YOURSELF',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.white,
                                letterSpacing: 1.3,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 17),
                      const Text(
                        'Find your strong.\nOne day at a time.',
                        style: TextStyle(
                          fontSize: 31,
                          height: 1.22,
                          letterSpacing: -0.9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Your only competition is who you were yesterday.',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFE2DCFF),
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Palette.mint,
                          foregroundColor: Palette.ink,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                        ),
                        onPressed: () => Navigator.pushNamed(
                          context,
                          controller.data.session == null
                              ? '/workouts'
                              : '/session',
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: Text(
                          controller.data.session == null
                              ? 'Let’s get moving'
                              : 'Resume your workout',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          right: const _WeeklyGoal(),
        ),
        const SizedBox(height: 24),
        ResponsiveGrid(
          minWidth: 145,
          children: [
            MetricCard(
              label: 'Active minutes',
              value: number(controller.totalMinutes),
              unit: 'min',
              icon: Icons.timer_outlined,
              color: Palette.primary,
              progress: controller.totalMinutes / goals.dailyMinutes,
              caption: 'of ${goals.dailyMinutes} min daily goal',
            ),
            MetricCard(
              label: 'Calories burned',
              value: number(controller.totalCalories),
              unit: 'kcal',
              icon: Icons.local_fire_department_outlined,
              color: Palette.orange,
              progress: controller.totalCalories / goals.dailyCalories,
              caption: 'of ${number(goals.dailyCalories)} kcal goal',
            ),
            MetricCard(
              label: 'Steps taken',
              value: number(controller.totalSteps),
              unit: 'steps',
              icon: Icons.directions_walk_rounded,
              color: Palette.blue,
              progress: controller.totalSteps / goals.dailySteps,
              caption: 'of ${number(goals.dailySteps)} daily goal',
            ),
            MetricCard(
              label: 'Daily streak',
              value: '${controller.streak}',
              unit: controller.streak == 1 ? 'day' : 'days',
              icon: Icons.bolt_rounded,
              color: const Color(0xFF3F9B79),
              progress: controller.streak / 7,
              caption: controller.streak == 0
                  ? 'Your next chapter starts today'
                  : 'Keep your momentum going',
            ),
          ],
        ),
        const SizedBox(height: 24),
        TwoColumn(
          breakpoint: 820,
          left: Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeading(
                  'Your activity rhythm',
                  subtitle: 'Every minute is a step forward.',
                  action: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: days,
                      isDense: true,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      items: const [
                        DropdownMenuItem(value: 7, child: Text('Last 7 days')),
                        DropdownMenuItem(
                          value: 28,
                          child: Text('Last 28 days'),
                        ),
                      ],
                      onChanged: (value) => setState(() => days = value!),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                ActivityChart(
                  values: controller.activitySeries(days),
                  endDate: controller.clock(),
                  goal: goals.dailyMinutes.toDouble(),
                ),
                const SizedBox(height: 18),
                Divider(color: Palette.border(context)),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 17,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${number(controller.activitySeries(days).fold<double>(0, (a, b) => a + b))} active minutes in the last $days days. Keep building your rhythm.',
                        style: TextStyle(
                          fontSize: 10,
                          color: Palette.muted(context),
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          right: const _HydrationCard(),
        ),
        const SizedBox(height: 24),
        TwoColumn(
          breakpoint: 820,
          left: Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeading(
                  'Recent activity',
                  subtitle: 'Effort worth remembering.',
                  action: TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/history'),
                    child: const Text(
                      'View all',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (recent.isEmpty)
                  EmptyState(
                    icon: Icons.history_rounded,
                    title: 'Your first move awaits',
                    message: 'Finish a workout or log an activity. Your journey will appear here.',
                    action: OutlinedButton(
                      onPressed: () => showWorkoutForm(context),
                      child: const Text('Log your first activity'),
                    ),
                  )
                else
                  ...recent.map((w) => WorkoutRow(workout: w)),
              ],
            ),
          ),
          right: Surface(
            color: const Color(0xFF25392F),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Tag(
                  'A MOMENT FOR YOU',
                  color: Color(0xFF347955),
                  icon: Icons.spa_outlined,
                ),
                const SizedBox(height: 20),
                const Icon(
                  Icons.self_improvement_rounded,
                  size: 47,
                  color: Color(0xFF5F9670),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Breathe. Stretch. Reset.',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Give your body a little love with a gentle, 20-minute yoga flow.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Palette.muted(context),
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => showPlan(context, plans[2]),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text(
                    'Explore the flow',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WeeklyGoal extends StatelessWidget {
  const _WeeklyGoal();
  @override
  Widget build(BuildContext context) {
    final controller = FitnessScope.of(context);
    final count = controller.thisWeek.length;
    final goal = controller.data.goalLevel.weeklyWorkouts;
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading('Weekly goal'),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<GoalLevel>(
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStateProperty.all(
                  const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              segments: GoalLevel.values
                  .map(
                    (level) => ButtonSegment(
                      value: level,
                      label: Text(level.label),
                      tooltip: level.description,
                    ),
                  )
                  .toList(),
              selected: {controller.data.goalLevel},
              onSelectionChanged: (selection) => runAction(
                context,
                () => controller.setGoalLevel(selection.first),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.data.goalLevel.description,
            style: TextStyle(fontSize: 9, color: Palette.muted(context)),
          ),
          const SizedBox(height: 14),
          Center(
            child: SizedBox(
              width: 110,
              height: 110,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: (count / goal).clamp(0, 1)),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => CircularProgressIndicator(
                        value: value,
                        color: Palette.primary,
                        strokeWidth: 9,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Palette.primary.withValues(
                          alpha: 0.09,
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$count / $goal',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'workouts',
                        style: TextStyle(
                          fontSize: 9,
                          color: Palette.muted(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final date = controller.weekStart.add(Duration(days: i));
              final done = controller.onDay(date).isNotEmpty;
              final today = sameDay(date, controller.clock());
              return Tooltip(
                message:
                    '${shortDate(date)}: ${controller.onDay(date).length} workouts',
                child: Column(
                  children: [
                    Text(
                      weekdays[i].substring(0, 1),
                      style: TextStyle(
                        fontSize: 9,
                        color: Palette.muted(context),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      width: 23,
                      height: 23,
                      decoration: BoxDecoration(
                        color: done ? Palette.primary : Palette.soft(context),
                        shape: BoxShape.circle,
                        border: today
                            ? Border.all(color: Palette.primary, width: 1.5)
                            : null,
                      ),
                      child: done
                          ? const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              count >= goal
                  ? 'Goal complete. Look at you go!'
                  : 'You’ve got this. One workout at a time.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, color: Palette.muted(context)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HydrationCard extends StatelessWidget {
  const _HydrationCard();
  @override
  Widget build(BuildContext context) {
    final controller = FitnessScope.of(context);
    final goal = controller.data.goalLevel.waterMl;
    final water = controller.waterToday;
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            'Stay hydrated',
            action: const Icon(
              Icons.water_drop_outlined,
              size: 19,
              color: Palette.blue,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            'A little sip goes a long way.',
            style: TextStyle(fontSize: 11, color: Palette.muted(context)),
          ),
          const SizedBox(height: 25),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 6,
            children: [
              Text(
                (water / 1000).toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Text(
                  '/ ${(goal / 1000).toStringAsFixed(2)} L',
                  style: TextStyle(fontSize: 12, color: Palette.muted(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (water / goal).clamp(0, 1),
              minHeight: 9,
              color: Palette.blue,
              backgroundColor: Palette.blue.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            water >= goal
                ? 'Hydration goal reached. Nicely done!'
                : '${((goal - water) / 1000).toStringAsFixed(2)} L to your daily goal',
            style: TextStyle(fontSize: 10, color: Palette.muted(context)),
          ),
          const SizedBox(height: 27),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: water >= 20000
                      ? null
                      : () =>
                            runAction(context, () => controller.addWater(250)),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('250 ml', style: TextStyle(fontSize: 11)),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.outlined(
                tooltip: 'Remove 250 ml',
                onPressed: water == 0
                    ? null
                    : () => runAction(context, () => controller.addWater(-250)),
                icon: const Icon(Icons.remove_rounded, size: 17),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            'Logged manually · resets each new day',
            style: TextStyle(fontSize: 9, color: Palette.muted(context)),
          ),
        ],
      ),
    );
  }
}
