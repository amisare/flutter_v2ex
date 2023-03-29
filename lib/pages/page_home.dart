import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_v2ex/http/dio_web.dart';
import 'package:flutter_v2ex/utils/storage.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:flutter_v2ex/components/home/search_bar.dart';
import 'package:flutter_v2ex/components/home/sticky_bar.dart';
import 'package:flutter_v2ex/components/home/tabbar_list.dart';
import 'package:flutter_v2ex/components/home/left_drawer.dart';
import 'package:flutter_v2ex/models/tabs.dart';
import 'package:flutter_v2ex/utils/event_bus.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  // 自定义、 缓存 、 api获取
  List<TabModel> tabs =
      GStorage().getTabs().where((item) => item.checked).toList();
  String shortcut = 'no action set';
  late TabController _tabController =
      TabController(vsync: this, length: tabs.length);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    eventBus.on('editTabs', (args) {
      _loadCustomTabs();
    });
    const QuickActions quickActions = QuickActions();
    quickActions.initialize((String shortcutType) {
      switch (shortcutType) {
        case 'hot':
          // 今日热议
          Get.toNamed('/hot');
          return;
        case 'sign':
          // 签到
          DioRequestWeb.dailyMission();
          return;
        case 'search':
          // 搜索
          Get.toNamed('/search');
      }
    });

    quickActions.setShortcutItems(<ShortcutItem>[
      // NOTE: This first action icon will only work on iOS.
      // In a real world project keep the same file name for both platforms.
      const ShortcutItem(
        type: 'hot',
        localizedTitle: '今日热门',
        icon: 'icon_hot',
      ),
      const ShortcutItem(
        type: 'sign',
        localizedTitle: '签到',
        icon: 'icon_sign',
      ),
      // NOTE: This second action icon will only work on Android.
      // In a real world project keep the same file name for both platforms.
      const ShortcutItem(
          type: 'search', localizedTitle: '搜索', icon: 'icon_search'),
    ]).then((void _) {
      setState(() {
        if (shortcut == 'no action set') {
          shortcut = 'actions ready';
        }
      });
    });
    // showPrivacyDialog();
  }

  void _loadCustomTabs() {
    var customTabs =
        GStorage().getTabs().where((item) => item.checked).toList();

    setState(() {
      tabs.clear();
      tabs.addAll(customTabs);
      _tabController = TabController(length: tabs.length, vsync: this);

      /// DefaultTabController在build外无法重新build tabView
      // DefaultTabController.of(context).animateTo(0);
    });
  }

  showPrivacyDialog() async {
    await Future.delayed(const Duration(milliseconds: 200));
    SmartDialog.show(builder: (context) {
      TextStyle style = Theme.of(context).textTheme.titleMedium!;
      return AlertDialog(
        title: const Text('欢迎使用VVEX'),
        content: Text.rich(
          TextSpan(children: [
            TextSpan(
                text: '我们非常重视您的个人信息及隐私保护！ 在您使用我们的产品前，请务必认真阅读', style: style),
            // TextSpan(
            //   text: '《用户协议》',
            //   style: style.copyWith(
            //     color: Theme.of(context).colorScheme.primary,
            //   ),
            //   recognizer: TapGestureRecognizer()..onTap = onClickUser,
            // ),
            // TextSpan(text: '、', style: style),
            TextSpan(
              text: '《隐私政策》',
              style: style.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
              recognizer: TapGestureRecognizer()..onTap = onClickPrivacy,
            ),
            TextSpan(text: '相关内容。 \n', style: style),
            TextSpan(text: '如您同意以上协议内容，请点击“同意”，开始使用我们的产品和服务。', style: style),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => SystemNavigator.pop(),
              child: const Text('不同意并退出')),
          TextButton(
              onPressed: () => SmartDialog.dismiss(), child: const Text('同意')),
        ],
      );
    });
  }

  onClickUser() {
    Get.toNamed('/agreement', parameters: {'source': 'user'});
  }

  onClickPrivacy() {
    Get.toNamed('/agreement', parameters: {'source': 'privacy'});
  }

  // 页面缓存
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    num height = MediaQuery.of(context).padding.top;
    GStorage().setStatusBarHeight(height);

    /// DefaultTabController在build外无法重新build tabView
    return Scaffold(
      drawer: const HomeLeftDrawer(),
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar(
                title: const HomeSearchBar(),
                automaticallyImplyLeading: false,
                pinned: true,
                floating: true,
                snap: true,
                forceElevated: innerBoxIsScrolled,
                bottom: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  onTap: (index) {},
                  isScrollable: true,
                  enableFeedback: true,
                  splashBorderRadius: BorderRadius.circular(6),
                  tabs: tabs.map((item) {
                    return Tab(text: item.name);
                  }).toList(),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: tabs.map((e) {
            return Builder(
              builder: (BuildContext context) {
                return CustomScrollView(
                  shrinkWrap: true,
                  key: PageStorageKey<String>(e.id),
                  slivers: <Widget>[
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                          context),
                    ),
                    // TabBarList(e),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              color: index % 2 == 0
                                  ? Colors.green
                                  : Colors.greenAccent,
                              height: 80,
                              alignment: Alignment.center,
                              child: Text(
                                "Item $index",
                                style: const TextStyle(fontSize: 30),
                              ),
                            ),
                          );
                          // return TabBarList(e);
                        },
                        childCount: 400,
                      ),
                    ),
                  ],
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
