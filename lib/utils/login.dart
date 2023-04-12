// ignore_for_file: avoid_print

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_v2ex/utils/cache.dart';

import 'event_bus.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_v2ex/utils/utils.dart';
import 'package:flutter_v2ex/utils/global.dart';
import 'package:flutter_v2ex/http/dio_web.dart';
import 'package:flutter_v2ex/utils/storage.dart';
import 'package:flutter_v2ex/pages/page_login.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';


class Login {

  static void onLogin() {
    Navigator.push(
      Routes.navigatorKey.currentContext!,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
        fullscreenDialog: true,
      ),
    ).then(
          (value) => {
        if (value['loginStatus'] == 'cancel')
          {SmartDialog.showToast('取消登录'), eventBus.emit('login', 'cancel')},
        if (value['loginStatus'] == 'success')
          {SmartDialog.showToast('登录成功'), eventBus.emit('login', 'success')}
      },
    );
  }

  static void loginDialog(
      String content, {
        String title = '提示',
        String cancelText = '取消',
        String confirmText = '去登录',
        bool isPopContext = false,
        bool isPopDialog = true,
      }) {
    SmartDialog.show(
      useSystem: true,
      animationType: SmartAnimationType.centerFade_otherSlide,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
                onPressed: () {
                  SmartDialog.dismiss();
                  isPopContext ? Navigator.pop(context) : null;
                },
                child: Text(cancelText)),
            TextButton(
                onPressed: () async {
                  if (isPopDialog) {
                    SmartDialog.dismiss()
                        .then((value) => Get.toNamed('/login'));
                  } else {
                    Get.toNamed('/login');
                  }
                },
                child: Text(confirmText))
          ],
        );
      },
    );
  }

  static void twoFADialog() {
    String _currentPage = Get.currentRoute;
    print('_currentPage: $_currentPage');
    var twoFACode = '';
    SmartDialog.show(
      useSystem: true,
      animationType: SmartAnimationType.centerFade_otherSlide,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('2FA 验证'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('你的 V2EX 账号已经开启了两步验证，请输入验证码继续'),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: '验证码',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                ),
                onChanged: (e) {
                  twoFACode = e;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () async{
                  await Login.signOut();
                  SmartDialog.dismiss();
                  eventBus.emit('login', 'cancel');
                  if(_currentPage == '/login' || _currentPage.startsWith('/t/')){
                    Get.back(result: {'loginStatus': 'cancel'});
                  }
                },
                child: const Text('取消')),
            TextButton(
                onPressed: () async {
                  if (twoFACode.length == 6) {
                    var res = await DioRequestWeb.twoFALOgin(twoFACode);
                    if (res == 'true') {
                      GStorage().setLoginStatus(true);
                      eventBus.emit('login', 'success');
                      SmartDialog.showToast('登录成功', displayTime: const Duration(milliseconds: 500)).then((res) {
                        // 登录页面需要关闭当前页面，其余情况只关闭dialog
                        SmartDialog.dismiss();
                        if(_currentPage == '/login') {
                          print('😊😊 - 登录成功');
                          Get.back(result: {'loginStatus': 'success'});
                        }
                      });
                    } else {
                      twoFACode = '';
                    }
                  } else {
                    SmartDialog.showToast(
                      '验证码有误',
                      displayTime: const Duration(milliseconds: 500),
                    );
                  }
                },
                child: const Text('登录'))
          ],
        );
      },
    );
  }

  static signOut() async{
    // 清除cookie数据
    Directory directory = Directory(await Utils.getCookiePath());
    await CacheManage().deleteDirectory(directory);
    // 重置登录状态
    GStorage().setLoginStatus(false);
    GStorage().setUserInfo({});
    GStorage().setSignStatus('');

    await DioRequestWeb.loginOut();
    // 重新设置cookie start
    List<Cookie> jarCookies = [];
    String cookiePath = await Utils.getCookiePath();
    PersistCookieJar cookieJar = PersistCookieJar(
      ignoreExpires: true,
      storage: FileStorage(cookiePath),
    );
    await cookieJar.saveFromResponse(
        Uri.parse("https://www.v2ex.com/"), jarCookies);
    Dio().interceptors.add(CookieManager(cookieJar));
    // setCookie.onSet([]);
    // 重新设置cookie end

    // 清除cookie
    // cookieJar.deleteAll();
    // CookieJar().deleteAll();

    // await cookieManager.cookieJar.deleteAll();
    // cookieManager.cookieJar.delete(Uri.parse("https://www.v2ex.com/"));
    // Request().dio.options.headers.update("cookie", (_) => "", ifAbsent: () => "");

    eventBus.emit('login', 'loginOut');
  }
}

