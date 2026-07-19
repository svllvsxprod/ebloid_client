<p align="center">
  <img src="assets/branding/eblo-favicon.svg" alt="Логотип Eblo.id" width="150" />
</p>

<h1 align="center">Eblo.id</h1>

<p align="center">
  Flutter-клиент eblo.id для iOS и Android с одной кодовой базой и единым интерфейсом.
</p>

<p align="center">
  <a href="https://eblo.id">Открыть eblo.id</a>
</p>

<table align="center">
  <tr>
    <td align="center" width="760">
      <h3>Поддержите разработку мобильного клиента</h3>
      <p>Поддержка помогает развивать мобильный клиент, тестировать платформенные сценарии и доводить проект до полноценного релиза.</p>
      <table align="center">
        <tr>
          <td align="center" width="350"><a href="https://t.me/tribute/app?startapp=dK9j"><img src="docs/readme/support-tribute.svg" width="340" alt="Поддержать разработку через Tribute" /></a></td>
          <td align="center" width="350"><a href="https://nowpayments.io/donation/svllvsx"><img src="docs/readme/support-nowpayments.svg" width="340" alt="Поддержать разработку через NOWPayments" /></a></td>
        </tr>
        <tr>
          <td align="center" colspan="2"><a href="https://t.me/svllvsxprod"><img src="docs/readme/telegram.svg" width="340" alt="Telegram-канал svllvsxprod" /></a></td>
        </tr>
      </table>
    </td>
  </tr>
</table>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-stable-02569B?style=for-the-badge&logo=flutter&logoColor=white">
  <img alt="Dart" src="https://img.shields.io/badge/Dart-stable-0175C2?style=for-the-badge&logo=dart&logoColor=white">
  <img alt="Android" src="https://img.shields.io/badge/Android-поддерживается-3DDC84?style=for-the-badge&logo=android&logoColor=white">
  <img alt="iOS" src="https://img.shields.io/badge/iOS-поддерживается-000000?style=for-the-badge&logo=apple&logoColor=white">
</p>

<p align="center">
  <a href="#возможности">Возможности</a> ·
  <a href="#интерфейс">Интерфейс</a> ·
  <a href="#архитектура">Архитектура</a> ·
  <a href="#запуск">Запуск</a> ·
  <a href="#модель-безопасности">Безопасность</a> ·
  <a href="#текущие-ограничения">Ограничения</a>
</p>

## О Проекте

Eblo.id — нативный по поведению мобильный клиент для просмотра и публикации пользовательского медиаконтента на [eblo.id](https://eblo.id).

Приложение использует одно Flutter-дерево интерфейса для iOS и Android. Платформенные различия изолированы в адаптерах авторизации, безопасного хранилища, выбора файлов, воспроизведения медиа, системной отправки ссылок и deep links.

Проект находится в активной разработке. Текущий код уже поддерживает основной пользовательский маршрут, но пока не считается готовым к публикации в App Store и Google Play.

## Интерфейс

<table>
  <tr>
    <th>Лента</th>
    <th>Публикация</th>
    <th>Создание</th>
    <th>Профиль</th>
  </tr>
  <tr>
    <td><img src="docs/readme/screenshots/ios-feed.png" alt="Лента Eblo.id на iOS" width="210" /></td>
    <td><img src="docs/readme/screenshots/ios-detail.png" alt="Публикация Eblo.id на iOS" width="210" /></td>
    <td><img src="docs/readme/screenshots/ios-create.png" alt="Создание публикации Eblo.id на iOS" width="210" /></td>
    <td><img src="docs/readme/screenshots/ios-profile.png" alt="Профиль Eblo.id на iOS" width="210" /></td>
  </tr>
</table>

## Возможности

- Публичная лента с фильтрами по типу медиа, сортировками, периодами, обновлением и пагинацией.
- Изображения, видео, аудио, одиночные публикации и альбомы.
- Экран публикации с исходным соотношением сторон, полноэкранным просмотром изображений и нативным воспроизведением медиа.
- Авторизация через Twitch внутри изолированного eblo.id WebView flow.
- Восстановление eblo.id session после перезапуска приложения.
- Upvote/downvote публикаций с восстановлением выбранной реакции.
- Реакции на комментарии и ответы с optimistic update и откатом при ошибке.
- Комментарии, вложенные ответы и переход к конкретному комментарию по deep link.
- Создание публикаций с изображениями, видео, аудио и несколькими файлами.
- Публичные публикации и публикации «По ссылке».
- Защищённый локальный черновик с сохранением порядка выбранных файлов.
- Прогресс загрузки, отмена и повтор после recoverable error.
- Публичные профили и публикации автора.
- Общий поиск по публикациям, видео и пользователям.
- Системная отправка канонической ссылки на публикацию.
- Единый адаптивный интерфейс для iOS и Android без платформенных копий экранов.

## Архитектура

```text
iOS / Android
  -> Flutter UI
  -> Riverpod controllers и dependency injection
  -> Domain models и repository interfaces
  -> Dio / platform adapters / secure storage
  -> подтверждённые web compatibility endpoints eblo.id
```

Основные принципы:

- `go_router` управляет общим route graph и deep links.
- UI зависит от domain models и controllers, а не от transport DTO.
- Remote, cache и platform logic скрыты за repository/adapters.
- API origin задаётся через проверенную build configuration.
- Неподтверждённые backend-возможности не подменяются фиктивными данными.
- Один media-first дизайн и одна тема используются на обеих платформах.

## Модель Безопасности

- Клиент сохраняет только eblo.id cookie `session`; Twitch cookies и tokens не переносятся в приложение.
- Session хранится через Keychain/Android Keystore-backed secure storage.
- CSRF token обновляется перед authenticated mutations.
- Session cookie передаётся только на точный HTTPS origin `eblo.id`.
- Upload filenames нормализуются и не раскрывают исходные локальные пути.
- Draft и локальные реакции разделяются по пользователю и очищаются по auth lifecycle.
- Tokens, cookies, тексты комментариев, media paths и signed URLs не должны попадать в logs.
- Cleartext traffic и отключение TLS validation не используются.

## Требования

- Flutter stable и совместимый Dart stable.
- Xcode для сборки iOS.
- Android Studio или Android SDK для сборки Android.
- Устройство или simulator/emulator для запуска.
- Сетевой доступ к `https://eblo.id`.

Текущая рабочая конфигурация проверена на Flutter `3.44.2` и Dart `3.12.2`.

## Запуск

Получить зависимости и проверить проект:

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
```

Посмотреть доступные устройства и запустить приложение:

```bash
flutter devices
flutter run -d <device-id>
```

Собрать debug APK:

```bash
flutter build apk --debug
```

Собрать приложение для iOS Simulator без подписи:

```bash
flutter build ios --simulator --debug --no-codesign
```

## Окружения

По умолчанию используется development-конфигурация с origin `https://eblo.id`.

Staging:

```bash
flutter run -d <device-id> \
  --dart-define=APP_ENV=staging \
  --dart-define=API_BASE_URL="$API_BASE_URL"
```

Production:

```bash
flutter run -d <device-id> \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL="$API_BASE_URL"
```

`API_BASE_URL` принимает только HTTPS origin без credentials, path, query и fragment. Secrets через Dart defines не передаются.

## Структура Проекта

```text
lib/app/                 composition root, router и theme
lib/core/                API, auth, domain, storage и общие widgets
lib/features/feed/       лента и фильтры
lib/features/post/       публикация, реакции и комментарии
lib/features/create_post/ создание, черновик и upload
lib/features/profile/    публичный профиль
lib/features/search/     общий поиск
lib/features/videos/     публичный раздел видео
test/                    unit и widget tests
```

## Документация

- README содержит публичное описание, команды сборки, архитектуру и известные ограничения.
- Внутренняя продуктовая, исследовательская и development-документация не публикуется в репозитории.

## Текущие Ограничения

- Turnstile/CAPTCHA challenge пока возвращается как recoverable blocker без встроенного challenge UI.
- Background/resumable upload и server-side cleanup требуют дополнительного backend/platform решения.
- Offline cache для feed, post, comments и profile ещё не завершён.
- Report, block/mute, account deletion и другие обязательные UGC store flows ещё не реализованы.
- Deep links и OAuth-return требуют финального physical smoke на поддерживаемых iOS/Android версиях.
- Notifications/push и полный video suggestion flow относятся к следующим релизам.

## Статус Разработки

Перед передачей изменений выполняются:

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
```

Последний проверенный baseline также проходит Android debug build и iOS Simulator build. Известные пользовательские ограничения перечислены выше.
