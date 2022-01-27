import 'dart:async';

import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';
// import 'riverpod_navigator_dart.dart';
import 'package:riverpod_navigator/riverpod_navigator.dart';

typedef NavigatorWidgetBuilder = Widget Function(BuildContext, Navigator);
typedef ScreenBuilder = Widget Function(TypedSegment segment);

final riverpodRouterDelegate = Provider<RiverpodRouterDelegate>((_) => throw UnimplementedError());

class RiverpodRouterDelegate extends RouterDelegate<TypedPath> with ChangeNotifier, PopNavigatorRouterDelegateMixin<TypedPath> {
  RiverpodRouterDelegate(this._ref, this._config, this._navigator) {
    _ref.listen(typedPathNotifierProvider, (_, __) => notifyListeners());
  }

  final RiverpodNavigator _navigator;
  final Ref _ref;
  final Config _config;

  @override
  TypedPath get currentConfiguration => _navigator.getActualTypedPath();

  @override
  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final actPath = _navigator.getActualTypedPath();
    if (actPath.isEmpty) return SizedBox();
    final navigatorWidget = Navigator(
        key: navigatorKey,
        // segment => screen
        pages: actPath.map((segment) => _config.screen2Page(segment, _config.screenBuilder)).toList(),
        onPopPage: (route, result) {
          //if (!route.didPop(result)) return false;
          // remove last segment from path
          _navigator.onPopRoute();
          return false;
        });
    return _config.navigatorWidgetBuilder == null ? navigatorWidget : _config.navigatorWidgetBuilder!(context, navigatorWidget);
  }

  @override
  Future<void> setNewRoutePath(TypedPath configuration) => _navigator.navigate(configuration);

  @override
  Future<void> setInitialRoutePath(TypedPath configuration) => _navigator.navigate(_config.initPath);
}

class RouteInformationParserImpl implements RouteInformationParser<TypedPath> {
  RouteInformationParserImpl(this._config);

  final Config4Dart _config;

  @override
  Future<TypedPath> parseRouteInformation(RouteInformation routeInformation) =>
      Future.value(_config.pathParser.path2TypedPath(routeInformation.location));

  @override
  RouteInformation restoreRouteInformation(TypedPath configuration) => RouteInformation(location: _config.pathParser.typedPath2Path(configuration));
}

typedef Screen2Page = Page Function(TypedSegment segment, ScreenBuilder screenBuilder);

class Config {
  Config({
    required this.screenBuilder,
    Screen2Page? screen2Page,
    required this.initPath,
    this.navigatorWidgetBuilder,
  }) : screen2Page = screen2Page ?? screen2PageDefault;
  final Screen2Page screen2Page;
  final ScreenBuilder screenBuilder;
  final TypedPath initPath;
  final NavigatorWidgetBuilder? navigatorWidgetBuilder;
}

final configProvider = Provider<Config>((_) => throw UnimplementedError());

final Screen2Page screen2PageDefault = (segment, screenBuilder) => _Screen2PageDefault(segment, screenBuilder);

class _Screen2PageDefault extends Page {
  _Screen2PageDefault(this._typedSegment, this._screenBuilder) : super(key: ValueKey(_typedSegment.asJson));

  final TypedSegment _typedSegment;
  final ScreenBuilder _screenBuilder;

  @override
  Route createRoute(BuildContext context) {
    // this line solved https://github.com/PavelPZ/riverpod_navigator/issues/2
    // https://github.com/flutter/flutter/issues/11655#issuecomment-469221502
    final child = _screenBuilder(_typedSegment);
    return MaterialPageRoute(
      settings: this,
      builder: (BuildContext context) => child,
    );
  }
}
