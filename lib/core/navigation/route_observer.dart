import 'package:flutter/widgets.dart';

///Lets screens react when they become visible again (e.g. the launcher
///refreshing its "Continue" card after a match was left)
final RouteObserver<ModalRoute<void>> appRouteObserver = RouteObserver<ModalRoute<void>>();
