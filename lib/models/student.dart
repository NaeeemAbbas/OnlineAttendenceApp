class Student {
  final String id;
  final String name;
  final String rollNumber;

  Student({
    required this.id,
    required this.name,
    required this.rollNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rollNumber': rollNumber,
    };
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      name: json['name'],
      rollNumber: json['rollNumber'],
    );
  }

  Student copyWith({
    String? id,
    String? name,
    String? rollNumber,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      rollNumber: rollNumber ?? this.rollNumber,
    );
  }
}