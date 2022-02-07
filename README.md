# Navigator for Riverpod

### Simple but powerfull navigation library (based on Flutter Navigator 2.0, [Riverpod](https://riverpod.dev/), and [Freezed](https://github.com/rrousselGit/freezed)) that solves the following problems:

- **Strictly typed navigation:** <br>You can use ```navigate([Home(), Books(), Book(id: bookId)]);``` instead of ```navigate('home/books/$bookId');``` in your code.
- **Easier coding:** <br>The problem of navigation is reduced to manipulation an immutable collection.
- **Better separation of concerns: UI x Model** (thanks to [riverpod](https://riverpod.dev/) :+1:):<br>
  Navigation logic can be developed and tested without typing a single flutter widget.
- **Asynchronous navigation:**<br>
  Prepare all necessary asynchronous operations before the navigation starts, e.g.
  - save data from the previous screen
  - loading data for new screen
- **Dependence on external providers:**<br>
  The navigation state may also depend on external providers, e.g. user login status
- **Possibility to configure many navigation parameters**, e.g. Page builder, Navigator builder, Splash screen

## The mission

Take a look at the following terms:

- **string path:** ```stringPath = 'home/books/book;id=2';```
- **string segment** - the string path consists of three string segments: 'home', 'books', 'book;id=2'
- **typed path**: ```typedPath = <TypedSegment>[HomeSegment(), BooksSegment(), BookSegment(id:2)];```
- **typed segment** - the typed path consists of three instances of [TypedSegment]'s: [HomeSegment], [BooksSegment], [BookSegment]
- **navigation stack** of Flutter Navigator 2.0: ```HomeScreen(HomeSegment())) => BooksScreen(BooksSegment()) => BookScreen(BookSegment(id:3))```

The mission of navigation is to keep *string path* <= **typed path** => *navigation stack* always in sync.
With **typed path** as the source of the truth.

## Examples

### Lesson01
- simple example

See [lesson01.dart source code](/examples/doc/lib/src/lesson01/lesson01.dart)

### 1. classes for typed path segments (aka TypedSegment)

From the following definition, [freezed package](https://github.com/rrousselGit/freezed) generates three typed segment classes: 
HomeSegment, BooksSegment and BookSegment.

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

### 2. App-specific navigator

- contains actions related to navigation. The actions are then used in the screen widgets.
- configures various navigation properties

```dart
class AppNavigator extends RiverpodNavigator {
  AppNavigator(Ref ref)
      : super(
          ref,
          initPath: [HomeSegment()],
          json2Segment: (jsonMap, _) => AppSegments.fromJson(jsonMap),
          screenBuilder: appSegmentsScreenBuilder,
        );

  Future<void> toHome() => navigate([HomeSegment()]);
  Future<void> toBooks() => navigate([HomeSegment(), BooksSegment()]);
  Future<void> toBook({required int id}) => navigate([HomeSegment(), BooksSegment(), BookSegment(id: id)]);
  Future<void> bookNextPrevButton({bool? isPrev}) {
    assert(currentTypedPath.last is BookSegment);
    var id = (currentTypedPath.last as BookSegment).id;
    if (isPrev == true)
      id = id == 0 ? booksLen - 1 : id - 1;
    else
      id = booksLen - 1 > id ? id + 1 : 0;
    return toBook(id: id);
  }
}
```

### 3. Root widget

Note: *To make it less verbose, we use the functional_widget package to generate widgets.
See generated "lesson??.g.dart"" file for details.*

```dart
@cwidget
Widget booksExampleApp(WidgetRef ref) {
  final navigator = ref.read(riverpodNavigatorProvider);
  return MaterialApp.router(
    title: 'Books App',
    routerDelegate: navigator.routerDelegate as RiverpodRouterDelegate,
    routeInformationParser: RouteInformationParserImpl(navigator.pathParser),
    debugShowCheckedModeBanner: false,
  );
}
```

### 4. App entry point

app entry point with ProviderScope's override

```dart
void runMain() => runApp(
    ProviderScope(
      overrides: [
        riverpodNavigatorCreatorProvider.overrideWithValue(AppNavigator.new /*See Constructor tear-offs in Dart ^2.15*/),
      ],
      child: const BooksExampleApp(),
    ),
  );
const booksLen = 5;
```

### 5. Map TypedSegment's to Screens

Only the *TypedSegment => Screen* mapping is displayed.. You can view all application widgets here: [screen.dart source code](/examples/doc/lib/src/lesson01/screens.dart)

```dart
final ScreenBuilder appSegmentsScreenBuilder = (segment) => (segment as AppSegments).map(
  // See Constructor tear-offs in Dart ^2.15, "HomeScreen.new" is equivalent to "(segment) => HomeScreen(segment)"
      home: HomeScreen.new,
      books: BooksScreen.new,
      book: BookScreen.new,
    );
```

## Other lessons:

### Lesson02
It enriches [lesson01](/doc/lesson01.md) by:

- screens require some asynchronous actions (when creating, deactivating or merging)
- the splash screen appears before the HomeScreen is displayed

See [lesson02 documentation](/doc/lesson02.md)

### Lesson03
It enriches  [lesson02](/doc/lesson02.md)  by:

- login application logic (where some pages are not available without a logged in user)
- more TypedPath roots (AppSegments and LoginSegments)
- navigation state also depends on another provider (userIsLoggedProvider)
- extension of the Lesson02

See [lesson03 documentation](/doc/lesson03.md)

### Lesson04
It modified [lesson03](/doc/lesson03.md) by:

- introduction of the route concept

See [lesson04 documentation](/doc/lesson04.md)

### Lesson05
Test for [lesson03](/doc/lesson03.md)

See [lesson05 documentation](/doc/lesson05.md)
## Todo