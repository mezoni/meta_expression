import 'macros.dart';

void main() {
  debug([r'\n']);
  debug(['E', 'e']);
  const name = 'Jack';
  const greetings = 'Hello, $name';
  debug(greetings);
  final list = [1, 2, 3];
  debug(list);
  debug([1, 2, 3]);
  get41(41);
}

int get41(int magicNumber) {
  if (magicNumber != 41) {
    throw ArgumentError.value(
        magicNumber, ident(magicNumber), 'Must be equal to 41');
  }

  return magicNumber;
}
