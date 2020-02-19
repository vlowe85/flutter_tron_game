enum KeyboardPress {
  RETURN,
  UP_ARROW, DOWN_ARROW, LEFT_ARROW, RIGHT_ARROW,
  W, A, S, D
}

final keyValues = EnumValues({
  4295426088: KeyboardPress.RETURN,
  4295426130: KeyboardPress.UP_ARROW,
  4295426129: KeyboardPress.DOWN_ARROW,
  4295426128: KeyboardPress.LEFT_ARROW,
  4295426127: KeyboardPress.RIGHT_ARROW,
  119: KeyboardPress.W,
  97: KeyboardPress.A,
  115: KeyboardPress.S,
  100: KeyboardPress.D,
});

class EnumValues<T> {
  Map<int, T> map;
  Map<T, int> reverseMap;

  EnumValues(this.map);

  Map<T, int> get reverse {
    if (reverseMap == null) {
      reverseMap = map.map((k, v) => new MapEntry(v, k));
    }
    return reverseMap;
  }
}