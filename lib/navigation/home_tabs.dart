/// Bottom navigation indices for [HomeShell].
abstract final class HomeTabs {
  static const int dashboard = 0;
  static const int schedule = 1;
  static const int scan = 2;
}

typedef HomeTabSelectedCallback = void Function(int index);
