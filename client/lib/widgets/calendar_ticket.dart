import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:talkie_v2/utils/lunar_calendar_utils.dart';

class CalendarTicket extends StatefulWidget {
  final Function(DateTime value) onChanged;
  const CalendarTicket({super.key, required this.onChanged});

  @override
  State<CalendarTicket> createState() => _CalendarTicketState();
}

class _CalendarTicketState extends State<CalendarTicket> {
  String title = "";
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  PageController _pageController = PageController();

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    widget.onChanged(_selectedDay);
  }

  @override
  void initState() {
    super.initState();
    DateTime initTime = DateTime.now();
    title = "T ${initTime.month}/${initTime.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 30,
              height: 30,
              padding: EdgeInsets.only(left: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey,
              ),
              child: IconButton(
                hoverColor: Colors.transparent,
                onPressed: () {
                  _pageController.previousPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
                padding: EdgeInsets.all(0.0),
                icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 16),
              ),
            ),
            Expanded(child: Center(child: Text(title))),
            IconButton(
              hoverColor: Colors.transparent,
              color: Colors.blue,
              onPressed: () {
                _focusedDay = DateTime.now();
                _pageController.animateToPage(
                  (_focusedDay.year - 1970) * 12 + _focusedDay.month - 1,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              padding: EdgeInsets.all(0.0),
              icon: Icon(Icons.refresh, size: 16),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey,
              ),
              child: IconButton(
                hoverColor: Colors.transparent,
                onPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
                padding: EdgeInsets.all(0.0),
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Center(child: Text('CN'))),
            Expanded(child: Center(child: Text('T2'))),
            Expanded(child: Center(child: Text('T3'))),
            Expanded(child: Center(child: Text('T4'))),
            Expanded(child: Center(child: Text('T5'))),
            Expanded(child: Center(child: Text('T6'))),
            Expanded(child: Center(child: Text('T7'))),
          ],
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            double rowHeight = 40;
            bool expanded = false;
            if (constraints.maxWidth > 260) {
              rowHeight = 50;
              expanded = true;
            }
            return TableCalendar(
              firstDay: DateTime.utc(2024, 1, 1),
              lastDay: DateTime.utc(2070, 1, 1),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: _onDaySelected,
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
                setState(() {
                  title = "T ${_focusedDay.month}/${_focusedDay.year}";
                });
              },
              headerVisible: false,
              daysOfWeekVisible: false,
              calendarFormat: CalendarFormat.month,
              onCalendarCreated: (controller) => _pageController = controller,
              calendarStyle: CalendarStyle(
                weekendTextStyle: TextStyle(color: Colors.amberAccent),
              ),
              rowHeight: rowHeight,
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  return buildCellCalendar(day, expandedHeight: expanded);
                },
                selectedBuilder: (context, day, focusedDay) {
                  return buildCellCalendar(
                    day,
                    expandedHeight: expanded,
                    select: Colors.orange,
                  );
                },
                todayBuilder: (context, day, focusedDay) {
                  return buildCellCalendar(
                    day,
                    expandedHeight: expanded,
                    select: Colors.orange.shade200,
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget buildCellCalendar(
    DateTime date, {
    Color select = Colors.white,
    bool expandedHeight = false,
  }) {
    String lunarDay = "";
    List<int> lunarCaculator = convertSolar2LunarByDateTime(date);
    int dd = lunarCaculator[0];
    int mm = lunarCaculator[1];
    if (dd == 1) {
      lunarDay += lunarCaculator[0].toString().padLeft(2, '0');
      if (mm < 10) {
        lunarDay += "/${lunarCaculator[1].toString().padLeft(2, '0')}";
      } else {
        lunarDay += "/${lunarCaculator[1]}";
      }
    } else {
      lunarDay += lunarCaculator[0].toString();
    }

    return Container(
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(color: select),
        child: !expandedHeight
            ? Center(
                child: Text(
                  "${date.day}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${date.day}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          lunarDay,
                          style: TextStyle(
                            color: dd == 1 || dd == 15
                                ? Colors.red
                                : Colors.black,
                            fontSize: dd == 1 ? 12 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
