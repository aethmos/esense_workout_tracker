class SensorValues {
  double x;
  double y;
  double z;
  void Function() onUpdate;

  SensorValues(this.x, this.y, this.z, [this.onUpdate]);

  SensorValues.fromList(List list, [this.onUpdate]) {
    this.x = list[0];
    this.y = list[1];
    this.z = list[2];
  }

  update(x, y, z) {
    this.x = x;
    this.y = y;
    this.z = z;
    if (onUpdate != null) onUpdate();
  }

  @override
  String toString() {
    return 'x ${this.x.toStringAsFixed(3)}' +
        '    y ${this.y.toStringAsFixed(3)}' +
        '    z ${this.z.toStringAsFixed(3)}';
  }

  toList() => [this.x, this.y, this.z];

  SensorValues operator +(SensorValues other) =>
      SensorValues(this.x + other.x, this.y + other.y, this.z + other.z);

  SensorValues operator -(SensorValues other) =>
      SensorValues(this.x - other.x, this.y - other.y, this.z - other.z);

  SensorValues operator /(number) =>
      SensorValues(this.x / number, this.y / number, this.z / number);

  SensorValues abs() => SensorValues(this.x.abs(), this.y.abs(), this.z.abs());

  bool operator >(other) {
    return this.x > other || this.y > other || this.z > other;
  }

  bool operator ==(other) {
    return this.x == other.x && this.y == other.y && this.z == other.z;
  }

  @override
  int get hashCode => super.hashCode;
}

class CombinedSensorEvent {
  DateTime timestamp;
  SensorValues phone;
  SensorValues eSense;

  CombinedSensorEvent.zero() {
    this.phone = SensorValues(0, 0, 0, onUpdate);
    this.eSense = SensorValues(0, 0, 0, onUpdate);
    this.timestamp = DateTime.now();
  }

  CombinedSensorEvent(phoneY, phoneX, phoneZ, eSenseX, eSenseY, eSenseZ) {
    this.phone = SensorValues(phoneY, phoneX, phoneZ, onUpdate);
    this.eSense = SensorValues(eSenseX, eSenseY, eSenseZ, onUpdate);
    this.timestamp = DateTime.now();
  }

  onUpdate() {
    this.timestamp = DateTime.now();
  }

  @override
  String toString() {
    return 'Acceleration\n' +
        '  Phone\n' +
        '    x ${this.phone.x.toStringAsFixed(3)}\n' +
        '    y ${this.phone.y.toStringAsFixed(3)}\n' +
        '    z ${this.phone.z.toStringAsFixed(3)}\n' +
        '  eSense\n' +
        '    x ${this.eSense.x.toStringAsFixed(3)}\n' +
        '    y ${this.eSense.y.toStringAsFixed(3)}\n' +
        '    z ${this.eSense.z.toStringAsFixed(3)}';
  }
}
