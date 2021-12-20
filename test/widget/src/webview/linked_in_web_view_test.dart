import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkedin_login/src/utils/configuration.dart';
import 'package:linkedin_login/src/utils/startup/graph.dart';
import 'package:linkedin_login/src/webview/linked_in_web_view_handler.dart';
import 'package:mockito/mockito.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import '../../../unit/utils/shared_mocks.mocks.dart';
import '../../../utils/webview_utils.dart';
import '../../../utils/webview_utils.mocks.dart';
import '../../widget_test_utils.dart';

void main() {
  Graph graph;
  List? actions;
  late WidgetTestbed testbed;

  TestWidgetsFlutterBinding.ensureInitialized();
  late MockWebViewPlatform mockWebViewPlatform;
  late MockWebViewPlatformController mockWebViewPlatformController;
  late MockWebViewCookieManagerPlatform mockWebViewCookieManagerPlatform;

  setUp(() {
    mockWebViewPlatformController = MockWebViewPlatformController();
    mockWebViewPlatform = MockWebViewPlatform();
    mockWebViewCookieManagerPlatform = MockWebViewCookieManagerPlatform();

    when(mockWebViewPlatform.build(
      context: anyNamed('context'),
      creationParams: anyNamed('creationParams'),
      webViewPlatformCallbacksHandler:
          anyNamed('webViewPlatformCallbacksHandler'),
      javascriptChannelRegistry: anyNamed('javascriptChannelRegistry'),
      onWebViewPlatformCreated: anyNamed('onWebViewPlatformCreated'),
      gestureRecognizers: anyNamed('gestureRecognizers'),
    )).thenAnswer((Invocation invocation) {
      final WebViewPlatformCreatedCallback onWebViewPlatformCreated =
          invocation.namedArguments[const Symbol('onWebViewPlatformCreated')]
              as WebViewPlatformCreatedCallback;
      return TestPlatformWebView(
        mockWebViewPlatformController: mockWebViewPlatformController,
        onWebViewPlatformCreated: onWebViewPlatformCreated,
      );
    });

    when(mockWebViewPlatformController.currentUrl())
        .thenAnswer((realInvocation) => Future.value(initialUrl));

    WebView.platform = mockWebViewPlatform;
    WebViewCookieManagerPlatform.instance = mockWebViewCookieManagerPlatform;

    graph = MockGraph();
    actions = [];

    _ArrangeBuilder(graph, actions);

    testbed = WidgetTestbed(
      graph: graph,
    );
  });

  tearDown(() {
    mockWebViewCookieManagerPlatform.reset();
  });

  testWidgets('is created', (WidgetTester tester) async {
    LinkedInWebViewHandler(
      onUrlMatch: (_) {},
    );
  });

  testWidgets('with app bar', (WidgetTester tester) async {
    final testWidget = testbed.injectWrap(
      child: LinkedInWebViewHandler(
        useVirtualDisplay: false,
        appBar: AppBar(
          title: Text('Title'),
        ),
        onUrlMatch: (_) {},
      ),
    );

    await tester.pumpWidget(testWidget);
    await tester.pumpAndSettle();

    expect(find.text('Title'), findsOneWidget);
  });

  testWidgets('test with initial url', (WidgetTester tester) async {
    late WebViewController controller;
    final testWidget = testbed.injectWrap(
      child: LinkedInWebViewHandler(
        useVirtualDisplay: false,
        onWebViewCreated: (webViewController) {
          controller = webViewController;
        },
        onUrlMatch: (_) {},
      ),
    );

    await tester.pumpWidget(testWidget);
    await tester.pumpAndSettle();

    expect(await controller.currentUrl(), initialUrl);
  });

  testWidgets(
      'callback for cookie clear is called when destroying session is active',
      (WidgetTester tester) async {
    var isCleared = false;
    final testWidget = testbed.injectWrap(
      child: LinkedInWebViewHandler(
        destroySession: true,
        onCookieClear: (value) => isCleared = value,
        onUrlMatch: (_) {},
      ),
    );

    await tester.pumpWidget(testWidget);
    await tester.pumpAndSettle();

    expect(isCleared, isTrue);
  });

  testWidgets(
      'callback for cookie clearing is not called when destroying session is inactive',
      (WidgetTester tester) async {
    var isCleared = false;
    final testWidget = testbed.injectWrap(
      child: LinkedInWebViewHandler(
        destroySession: false,
        onCookieClear: (value) => isCleared = value,
        onUrlMatch: (_) {},
      ),
    );

    await tester.pumpWidget(testWidget);
    await tester.pumpAndSettle();

    expect(isCleared, isFalse);
  });
}

class _ArrangeBuilder {
  _ArrangeBuilder(
    this.graph,
    this.actions, {
    Config? configuration,
  }) : _configuration = configuration ?? MockConfig() {
    when(graph.linkedInConfiguration).thenAnswer((_) => _configuration);

    withConfiguration();
  }

  final List<dynamic>? actions;
  final Graph graph;
  final Config _configuration;

  void withConfiguration() {
    when(_configuration.initialUrl).thenAnswer((_) =>
        'https://www.linkedin.com/oauth/v2/authorization?response_type=code&client_id=12345&state=null&redirect_uri=https://www.app.dexter.com&scope=r_liteprofile%20r_emailaddress');
  }

  void withUrlNotMatch(String url) {
    when(_configuration.isCurrentUrlMatchToRedirection(url))
        .thenAnswer((_) => false);
  }

  void withUrlMatch(String url) {
    when(_configuration.isCurrentUrlMatchToRedirection(url))
        .thenAnswer((_) => true);
  }
}
