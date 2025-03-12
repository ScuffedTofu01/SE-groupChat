import 'package:intl/intl.dart';
import '/utilities/input_field.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/utilities/asset_manager.dart'; 
import '/main_screen/setting_screen.dart';
import '/utilities/add_event_button.dart';


class AddEventPage extends StatefulWidget {
  const AddEventPage({super.key});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  DateTime _selectedDate = DateTime.now();
  String _startTime = DateFormat("h:mm a").format(DateTime.now()).toString();
  String _endTime = DateFormat("h:mm a").format(DateTime.now()).toString();

  _getDateFromUser() async {
    DateTime? _pickDate = await showDatePicker(
      context: context, 
      initialDate: DateTime.now(),
      firstDate: DateTime(2010), 
      lastDate: DateTime(2035)
    );
    
    if (_pickDate != null && _pickDate != _selectedDate) {
      setState(() {
        _selectedDate = _pickDate;
      });
    } else {
      print("Something went wrong while picking the date.");
    }
  }

  _getTimeFromUser({required bool isStartTime}) async {
    TimeOfDay? pickedTime = await _showTimePicker();

    if (pickedTime != null) {
      final formattedTime = pickedTime.format(context);
      setState(() {
        if (isStartTime) {
          _startTime = formattedTime;
        } else {
          _endTime = formattedTime;
        }
      });
    } else {
      print("No time selected");
    }
  }

  _showTimePicker() {
    return showTimePicker(
      initialEntryMode: TimePickerEntryMode.input,
      context: context, 
      initialTime: TimeOfDay(
        hour: int.parse(_startTime.split(":")[0]), 
        minute: int.parse(_startTime.split(":")[1].split(" ")[0]),
      ),
    );
  }

  _colorPicker(){
               return   Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                       "Colour",
                        style: TextStyle(
                            fontSize: 16,  
                        ),
                    ),
                  ),
                  SizedBox(height: 8), 
                  Wrap(
                    spacing: 8.0,
                    children: List<Widget>.generate(
                      colorList.length,
                      (int index) {
                        return GestureDetector(
                          onTap: (){
                              setState(() {
                                _selectedColour = index;
                              });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(left: 5.0),
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: colorList[index],  
                              child: _selectedColour==index?Icon(
                                Icons.done,
                                color: Colors.white,
                                size: 20,):Container(),
                            )
                          ),
                        );
                      }
                    ),
                  ),
                ],
              );
  }
  
  final List<Color> colorList = [
    Color(0xFFB9A2FF), 
    Color(0xFF45A1FF), 
    Color(0xFF93C572), 
    Color(0xFFFFB93E), 
    Color(0xFFF24C5B),
  ];
  int _selectedColour = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _topBar(context), 
      body: Container(
        padding: const EdgeInsets.only(top: 20, left: 10, right: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Create Event",
                style: GoogleFonts.lato(
                  fontSize: 40, 
                  fontWeight: FontWeight.w600,
                ),
              ),
              InputField(title: 'Event Name', hint: 'Enter event name'),
              InputField(title: 'Event Note', hint: 'Enter Event Description'),
              InputField(
                title: 'Event Date', 
                hint: DateFormat('d/MM/yyyy').format(_selectedDate),
                widget: IconButton(
                  onPressed: _getDateFromUser,  
                  icon: Icon(Icons.calendar_today_outlined),
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: InputField(
                      title: 'Start Time', 
                      hint: _startTime,
                      widget: IconButton(
                        onPressed: () {
                          _getTimeFromUser(isStartTime: true);  
                        },
                        icon: Icon(
                          Icons.access_time_rounded,
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: InputField(
                      title: 'End Time',  
                      hint: _endTime,
                      widget: IconButton(
                        onPressed: () {
                          _getTimeFromUser(isStartTime: false);
                        },
                        icon: Icon(
                          Icons.access_time_rounded,
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              _colorPicker(),
              Padding(
                padding: const EdgeInsets.only(top: 30, left: 0),
                child: AddEventButton(
                  label: "Create Event", onTap: ()=>null),
                )
          
            ],
          ),
        ),
      ),
    );
  }
}

PreferredSizeWidget _topBar(BuildContext context) {  
  return AppBar(
    actions: [
      Padding(
        padding: const EdgeInsets.only(top: 10, right: 30.0, left: 10),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingScreen()),
            );
          },
          child: CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage(AssetManager.userImage), 
          ),
        ),
      ),
    ],
  );
}
