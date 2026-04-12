import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class BookingDateTimeSheet extends StatefulWidget {
  final String deviceName;
  final DateTime initialDate;
  final TimeOfDay initialStartTime;
  final TimeOfDay initialEndTime;
  final void Function(DateTime date, TimeOfDay start, TimeOfDay end) onConfirm;

  const BookingDateTimeSheet({
    super.key,
    required this.deviceName,
    required this.initialDate,
    required this.initialStartTime,
    required this.initialEndTime,
    required this.onConfirm,
  });

  @override
  State<BookingDateTimeSheet> createState() => _BookingDateTimeSheetState();
}

class _BookingDateTimeSheetState extends State<BookingDateTimeSheet> {
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _startTime = widget.initialStartTime;
    _endTime = widget.initialEndTime;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        top: 20,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryGradientStart,
                        AppTheme.primaryGradientEnd,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.calendar_month, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Đặt lịch sử dụng",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        widget.deviceName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Date Display - Tap to show calendar picker
            _DateSelector(
              selectedDate: _selectedDate,
              onDateChanged: (date) => setState(() => _selectedDate = date),
            ),
            const SizedBox(height: 16),

            // Time Display
            Row(
              children: [
                Expanded(
                  child: _TimeSelector(
                    label: "Bắt đầu",
                    time: _startTime,
                    onTimeChanged: (time) {
                      setState(() {
                        _startTime = time;
                        if (_endTime.hour < _startTime.hour ||
                            (_endTime.hour == _startTime.hour &&
                                _endTime.minute <= _startTime.minute)) {
                          _endTime = TimeOfDay(
                            hour: (_startTime.hour + 1) % 24,
                            minute: _startTime.minute,
                          );
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeSelector(
                    label: "Kết thúc",
                    time: _endTime,
                    onTimeChanged: (time) => setState(() => _endTime = time),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey),
                    ),
                    child: const Text("HỦY"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onConfirm(_selectedDate, _startTime, _endTime);
                      Navigator.pop(context, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGradientStart,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("ĐẶT LỊCH"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const _DateSelector({
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showCalendarPicker(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGradientStart.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.calendar_today, color: AppTheme.primaryGradientStart, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ngày",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Future<void> _showCalendarPicker(BuildContext context) async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CustomCalendarPicker(
        initialDate: selectedDate,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      ),
    );
    if (picked != null) {
      onDateChanged(picked);
    }
  }
}

class _TimeSelector extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onTimeChanged;

  const _TimeSelector({
    required this.label,
    required this.time,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showWheelTimePicker(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(
              time.format(context),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showWheelTimePicker(BuildContext context) async {
    final result = await showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TimeWheelPickerSheet(
        initialTime: time,
        title: label,
      ),
    );
    if (result != null) {
      onTimeChanged(result);
    }
  }
}

class _TimeWheelPickerSheet extends StatefulWidget {
  final TimeOfDay initialTime;
  final String title;

  const _TimeWheelPickerSheet({
    required this.initialTime,
    required this.title,
  });

  @override
  State<_TimeWheelPickerSheet> createState() => _TimeWheelPickerSheetState();
}

class _TimeWheelPickerSheetState extends State<_TimeWheelPickerSheet> {
  late int _selectedHour;
  late int _selectedMinute;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialTime.hour;
    _selectedMinute = widget.initialTime.minute;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          // Wheel Pickers
          SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildWheelColumn(
                  label: "Giờ",
                  items: List.generate(24, (i) => i),
                  selectedItem: _selectedHour,
                  onChanged: (value) => setState(() => _selectedHour = value),
                ),
                const SizedBox(width: 24),
                _buildWheelColumn(
                  label: "Phút",
                  items: List.generate(60, (i) => i),
                  selectedItem: _selectedMinute,
                  format: (i) => i.toString().padLeft(2, '0'),
                  onChanged: (value) => setState(() => _selectedMinute = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Text("HỦY"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        TimeOfDay(hour: _selectedHour, minute: _selectedMinute),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGradientStart,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("XÁC NHẬN"),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildWheelColumn({
    required String label,
    required List<int> items,
    required int selectedItem,
    String Function(int)? format,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SizedBox(
            width: 70,
            child: ListWheelScrollView.useDelegate(
              itemExtent: 50,
              perspective: 0.005,
              diameterRatio: 1.2,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: onChanged,
              childDelegate: ListWheelChildBuilderDelegate(
                builder: (context, index) {
                  final value = items[index];
                  final isSelected = value == selectedItem;
                  return Center(
                    child: Text(
                      format?.call(value) ?? value.toString(),
                      style: TextStyle(
                        fontSize: isSelected ? 28 : 22,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? AppTheme.primaryGradientStart
                            : Colors.grey.shade400,
                      ),
                    ),
                  );
                },
                childCount: items.length,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Beautiful custom calendar picker
class _CustomCalendarPicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _CustomCalendarPicker({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_CustomCalendarPicker> createState() => _CustomCalendarPickerState();
}

class _CustomCalendarPickerState extends State<_CustomCalendarPicker> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          // Handle
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          // Header: Month Year with navigation
          _buildHeader(),
          const SizedBox(height: 16),
          // Weekday labels
          _buildWeekdayLabels(),
          const SizedBox(height: 8),
          // Calendar grid
          _buildCalendarGrid(),
          const SizedBox(height: 20),
          // Action buttons
          _buildActions(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final months = [
      "Tháng 1", "Tháng 2", "Tháng 3", "Tháng 4", "Tháng 5", "Tháng 6",
      "Tháng 7", "Tháng 8", "Tháng 9", "Tháng 10", "Tháng 11", "Tháng 12"
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: Icon(Icons.chevron_left, color: AppTheme.primaryGradientStart),
            iconSize: 28,
          ),
          Column(
            children: [
              Text(
                months[_currentMonth.month - 1],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                "${_currentMonth.year}",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: Icon(Icons.chevron_right, color: AppTheme.primaryGradientStart),
            iconSize: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayLabels() {
    final weekdays = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: weekdays.map((day) {
          final isWeekend = day == "T7" || day == "CN";
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isWeekend ? Colors.red.shade400 : Colors.grey.shade600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final startingWeekday = firstDayOfMonth.weekday; // 1 = Monday
    final daysInMonth = lastDayOfMonth.day;

    // Create empty cells for days before the first day of month
    final List<DateTime?> days = [];
    for (int i = 1; i < startingWeekday; i++) {
      days.add(null);
    }
    // Add days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, day));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1,
        ),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final date = days[index];
          if (date == null) return const SizedBox();

          final isSelected = _isSameDay(date, _selectedDate);
          final isToday = _isSameDay(date, DateTime.now());
          final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
          final isWeekend = date.weekday == 7 || date.weekday == 1;

          return GestureDetector(
            onTap: isPast ? null : () => _selectDate(date),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [AppTheme.primaryGradientStart, AppTheme.primaryGradientEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isToday && !isSelected ? AppTheme.primaryGradientStart.withValues(alpha: 0.1) : null,
                borderRadius: BorderRadius.circular(12),
                border: isToday && !isSelected
                    ? Border.all(color: AppTheme.primaryGradientStart, width: 2)
                    : null,
              ),
              child: Center(
                child: Text(
                  "${date.day}",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? Colors.white
                        : isPast
                            ? Colors.grey.shade300
                            : isWeekend
                                ? Colors.red.shade400
                                : Color(0xFF1E293B),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: const Text("HỦY"),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _selectedDate),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGradientStart,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("CHỌN"),
            ),
          ),
        ],
      ),
    );
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta);
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}