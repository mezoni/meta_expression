void main() {
  print("[r'\\n']");
  print("['E', 'e']");

  const name = 'Jack';
  const greetings = 'Hello, $name';
  print('greetings = $greetings');

  final list = [1, 2, 3];
  print('list = $list');
  print('[1, 2, 3]');

  get41(41);
}

int get41(int magicNumber) {
  if (magicNumber != 41) {
    throw ArgumentError.value(
        magicNumber, 'magicNumber', 'Must be equal to 41');
  }

  return magicNumber;
}
