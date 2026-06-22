typedef Foo = List<int>;

class Bar {
  final Foo items;

  Bar([Foo? items]) : items = items ?? <int>[];
}
