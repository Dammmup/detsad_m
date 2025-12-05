# Инструкция по настройке Google Maps API

Для отображения карты в приложении необходимо получить API-ключ от Google и добавить его в конфигурацию для Android и iOS.

## Шаг 1: Получение API-ключа

1.  **Перейдите в [Google Cloud Console](https://console.cloud.google.com/)**.
2.  **Создайте новый проект** или выберите существующий.
3.  **Включите API**:
    *   В меню навигации выберите **"APIs & Services" -> "Library"**.
    *   Найдите и включите **"Maps SDK for Android"**.
    *   Найдите и включите **"Maps SDK for iOS"**.
4.  **Создайте API-ключ**:
    *   Перейдите в **"APIs & Services" -> "Credentials"**.
    *   Нажмите **"Create Credentials" -> "API key"**.
    *   **Скопируйте созданный ключ**.
5.  **Ограничьте ключ (Рекомендуется)**:
    *   В списке ключей нажмите на ваш новый ключ.
    *   В разделе **"Application restrictions"** выберите "Android apps" и/или "iOS apps" и следуйте инструкциям, чтобы добавить ограничения для вашего приложения (понадобится `package name` для Android и `bundle ID` для iOS).
    *   В разделе **"API restrictions"** выберите "Restrict key" и выберите только "Maps SDK for Android" и "Maps SDK for iOS".

## Шаг 2: Настройка для Android

1.  Откройте файл: `android/app/src/main/AndroidManifest.xml`.
2.  Добавьте следующий мета-тег внутрь тега `<application>`, заменив `"YOUR_API_KEY"` на ваш ключ:

    ```xml
    <application
        ...
        >
        ...
        <meta-data android:name="com.google.android.geo.API_KEY"
                   android:value="YOUR_API_KEY"/>
        ...
    </application>
    ```

## Шаг 3: Настройка для iOS

1.  Откройте файл: `ios/Runner/AppDelegate.swift`.
2.  Импортируйте `GoogleMaps` в начале файла:

    ```swift
    import UIKit
    import Flutter
    import GoogleMaps // <-- Добавьте эту строку
    ```

3.  В методе `application(_:didFinishLaunchingWithOptions:)` добавьте вызов `GMSServices.provideAPIKey`, заменив `"YOUR_API_KEY"` на ваш ключ. Это нужно сделать **перед** `GeneratedPluginRegistrant.register(with: self)`.

    ```swift
    @UIApplicationMain
    @objc class AppDelegate: FlutterAppDelegate {
      override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
      ) -> Bool {
        GMSServices.provideAPIKey("YOUR_API_KEY") // <-- Добавьте эту строку
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
      }
    }
    ```

## Шаг 4: Обновление Info.plist для iOS

1.  Откройте файл `ios/Runner/Info.plist`.
2.  Добавьте следующую строку в основной словарь `<dict>`:

    ```xml
    <key>io.flutter.embedded_views_preview</key>
    <true/>
    ```

**После выполнения этих шагов и перезапуска приложения карта должна будет отображаться.**
