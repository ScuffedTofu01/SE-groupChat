class Event {
  String? eventId;
  String? title;
  String? note;
  int? isDone;
  String? date;
  String? startTime;
  String? endTime;
  int? color;

  Event({
    this.eventId,
    this.title,
    this.note,
    this.isDone,
    this.date,
    this.startTime,
    this.endTime,
    this.color,
  });


  Event.fromJson(Map<String, dynamic> json) {
    eventId = json['eventId'];  
    title = json['title'];
    note = json['note'];
    isDone = json['isDone'];
    date = json['date'];
    startTime = json['startTime'];
    endTime = json['endTime'];
    color = json['color'];
  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = title;
    data['note'] = note;
    data['isDone'] = isDone;
    data['date'] = date;
    data['startTime'] = startTime;
    data['endTime'] = endTime;
    data['color'] = color;
    return data;
  }
}
