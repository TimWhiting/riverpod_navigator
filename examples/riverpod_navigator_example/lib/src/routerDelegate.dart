import 'dart:async';

import 'package:flutter/material.dart';

import 'navigator.dart';
import 'widgets.dart';

class RiverpodRouterDelegate extends RouterDelegate<TypedPath> with ChangeNotifier, PopNavigatorRouterDelegateMixin<TypedPath> {
  RiverpodRouterDelegate();

  RiverpodNavigator? navigator;
  RiverpodNavigator get _navigator => navigator as RiverpodNavigator;

  // make [notifyListeners] public
  void doNotifyListener() => notifyListeners();

  @override
  TypedPath currentConfiguration = [];

  @override
  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final actPath = currentConfiguration;
    if (actPath.isEmpty) return SizedBox();

    final screenBuilder = (ExampleSegments segment) => segment.map(
          home: (homeSegment) => HomeScreen(homeSegment),
          books: (booksSegment) => BooksScreen(booksSegment),
          book: (bookSegment) => BookScreen(bookSegment),
        );
    return Navigator(
        key: navigatorKey,
        pages: actPath.map((segment) => MaterialPage(key: ValueKey(segment.toString), child: screenBuilder(segment))).toList(),
        onPopPage: (route, result) {
          if (!route.didPop(result)) return false;
          // remove last segment from path
          return _navigator.onPopRoute();
        });
  }

  @override
  Future<void> setNewRoutePath(TypedPath configuration) async => _navigator.navigate(configuration);

  @override
  Future<void> setInitialRoutePath(TypedPath configuration) async => _navigator.navigate([HomeSegment()]);
}
