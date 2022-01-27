# Riverpod_Navigator

### Navigation library (based on Flutter Navigator 2.0) that solves the following problems:

- **Strictly typed navigation:** <br>You can use ```navigate([Home(), Books(), Book(id: bookId)]);``` instead of ```navigate('home/books/$bookId');``` in your code.
- **Easier coding:** <br>The problem of navigation is reduced to manipulation of the immutable collection.
- **Better separation of concerns: UI x Model** (riverpod offers this feature too): <br>
  Navigation logic can be developed and tested in the Dart environment, without typing a single flutter widget. 
- **Small codebase with a lot of extensions:**<br>
  The core engine consists of two small .dart files ([riverpod_navigator.dart](packages/riverpod_navigator/lib/src/riverpod_navigator.dart) 
  and [riverpod_navigator_dart.dart](packages/riverpod_navigator_dart/lib/src/riverpod_navigator_dart.dart))
  Additional features (such as better URL parser, asynchronous navigation, possibility to use routes etc.) are included as configurable extensions.

*For a better understanding, everything is explained on the classic 3-screens example: [Home] => [Books] => [Book\*]*

## Lesson01 - simple example

Whole example is available [here]() 

### 1. Classes for typed url-path-segments (TypedSegment)

The Freezed package generates three immutable classes used for writing typed navigation path,
e.g ```TypedPath path = [HomeSegment (), BooksSegment () and BookSegment (id: 3)];```

```dart
@freezed
class AppSegments with _$AppSegments, TypedSegment {
  AppSegments._();
  factory AppSegments.home() = HomeSegment;
  factory AppSegments.books() = BooksSegment;
  factory AppSegments.book({required int id}) = BookSegment;

  factory AppSegments.fromJson(Map<String, dynamic> json) => _$AppSegmentsFromJson(json);
}
```

### 2. Dart-part of app configuration

```dart
final config4DartCreator = () => Config4Dart(json2Segment: (json, _) => AppSegments.fromJson(json));
```

### 3. app-specific navigator with navigation aware actions (used in screens)

```dart
const booksLen = 5;

class AppNavigator extends RiverpodNavigator {
  AppNavigator(Ref ref, Config4Dart config) : super(ref, config);

  void toHome() => navigate([HomeSegment()]);
  void toBooks() => navigate([HomeSegment(), BooksSegment()]);
  void toBook({required int id}) => navigate([HomeSegment(), BooksSegment(), BookSegment(id: id)]);
  void bookNextPrevButton({bool? isPrev}) {
    assert(getActualTypedPath().last is BookSegment);
    var id = (getActualTypedPath().last as BookSegment).id;
    if (isPrev == true)
      id = id == 0 ? booksLen - 1 : id - 1;
    else
      id = booksLen - 1 > id ? id + 1 : 0;
    toBook(id: id);
  }
}
```

### 4. providers

```dart
final appNavigatorProvider = Provider<AppNavigator>((ref) => AppNavigator(ref, ref.watch(config4DartProvider)));

/// Provider with Flutter 2.0 RouterDelegate
final appRouterDelegateProvider =
    Provider<RiverpodRouterDelegate>((ref) => RiverpodRouterDelegate(ref, ref.watch(configProvider), ref.watch(appNavigatorProvider)));
```
### 5. Flutter-part of app configuration

```dart
final configCreator = () => Config(
      /// Which widget will be builded for which [TypedSegment].
      /// Used in [RiverpodRouterDelegate] to build pages from [TypedSegment]'s
      screenBuilder: (segment) => (segment as AppSegments).map(
        home: (home) => HomeScreen(home),
        books: (books) => BooksScreen(books),
        book: (book) => BookScreen(book),
      ),

      /// specify home path of app
      initPath: [HomeSegment()],
    );
```
### 6. root widget for app

Using functional_widget package to be less verbose. Package generates "class BooksExampleApp extends ConsumerWidget...", see *.g.dart

```dart
@cwidget
Widget booksExampleApp(WidgetRef ref) => MaterialApp.router(
      title: 'Books App',
      routerDelegate: ref.watch(appRouterDelegateProvider),
      routeInformationParser: RouteInformationParserImpl(ref.watch(config4DartProvider)),
    );
```
### 7. app entry point with ProviderScope

/// Using functional_widget package to be less verbose. Package generates "class BooksExampleApp extends ConsumerWidget...", see *.g.dart
void main() {
  runApp(ProviderScope(
    // initialize configs providers
    overrides: [
      config4DartProvider.overrideWithValue(config4DartCreator()),
      configProvider.overrideWithValue(configCreator()),
    ],
    child: const BooksExampleApp(),
  ));
}
```