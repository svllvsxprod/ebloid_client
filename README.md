# ebloid_client

Flutter-клиент eblo.id для iOS и Android с одной кодовой базой и одним деревом UI.

## Текущий статус

- Обычный debug runtime использует публичный read-only API eblo.id для ленты, комментариев, публикаций профиля и раздела видео.
- Реализованы фильтры, сортировки, pagination, media/avatar URLs и routes `/feed`, `/post/:shortCode`, `/create`, `/videos`, `/profile`, `/profile/:login`, `/auth/twitch`.
- Поиск использует public `GET /api/search/all`: профили открываются нативно, post/video results с неполным DTO — через проверенный HTTPS system-browser adapter.
- Public media принимается по HTTPS; относительные URL разрешаются от `https://eblo.id`.
- Доступные публичные посты отправляются через системный share sheet с канонической ссылкой `https://eblo.id/{shortCode}`.
- Detail использует native playback: `video_player` для server-defined video и `just_audio` для audio; autoplay отключён, ошибки codec/container изолированы внутри media shell.
- Audio cards используют отдельный waveform preview без несуществующего thumbnail; author rows открывают public profile и возвращаются через обычный route stack.
- Video controls скрываются по tap/таймеру; fullscreen использует тот же controller и сохраняет playback position.
- Create использует системный multi-file picker для изображений, видео и аудио; локальный черновик сохраняет порядок и media handles в secure storage и повторно проверяет их доступность после restart.
- Upload/publish, reactions, comment mutations, owner profile и Twitch OAuth не имитируются: неподтверждённые действия скрыты или показывают контрактный blocker.
- Business fixtures, local media assets и fake repositories отсутствуют.
- Игры исключены из mobile scope решением владельца продукта.

## Источники

- `tz.md` - основной продуктовый документ.
- `docs/research/` - подтверждённое поведение, API-границы и открытые вопросы.
- `docs/research/endpoint-catalog.md` - индекс web/API endpoint-ов и JS sources для compatibility diagnostics.
- `docs/implementation-checklist.md` - актуальный статус готовых, частичных и отсутствующих функций.
- `design/` - визуальный handoff; HTML/CSS используется только как спецификация.

## Архитектура

- Один Material 3 UI tree для iOS и Android.
- `go_router` для общего route graph.
- Riverpod для repository/controller composition.
- Dio получает HTTPS origin из проверенной build configuration; текущий runtime использует его только для подтверждённых public read paths.
- Repository/provider defaults являются unavailable adapters; `main.dart` подключает реальные read-only repositories.
- Draft storage использует Android Keystore-backed defaults и iOS Keychain без insecure fallback.
- Web session foundation хранит только validated eblo.id cookies и CSRF token в Keychain/Keystore-backed secure storage; direct mutations блокируются при storage failure, public GET продолжают работать.
- Test-only doubles используются только для проверки технических контрактов хранения и не содержат постов, пользователей или media content.

Текущий клиент не является production-ready. Twitch OAuth, standalone detail deep links, полные profile metadata и production uploads заблокированы соответствующими `TODO(API)`. Сохранённые picker paths могут стать недоступны после очистки platform cache; такой media item явно помечается и может быть удалён или заменён.

## Environments

- `development`: текущий runtime с публичными feed, comments, profile uploads и videos endpoints; выбран по умолчанию.
- `staging`: выбирается через `--dart-define=APP_ENV=staging` и требует явный HTTPS `API_BASE_URL`.
- `production`: выбирается через `--dart-define=APP_ENV=production`; до закрытия production contracts остаётся read-only.

`API_BASE_URL` принимает только HTTPS origin без credentials, path, query и fragment. Secrets через Dart defines не передаются.

## TODO(API)

До production-интеграции должны быть закрыты: `AUTH-01`, `FEED-01`, `POST-01`, `VOTE-01`, `COMMENT-01`, `UPLOAD-01`, `PUBLISH-01`, `PROFILE-01`, `REPORT-01`, `ACCOUNT-01`, `BLOCK-01`, `ERROR-01`, `DEEPLINK-01`, `NOTIFY-01`, `VIDEO-01`.

Подробности находятся в `docs/research/api-notes.md` и `docs/research/open-questions.md`.

## Запуск

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter devices
flutter run -d <device-id>
flutter run -d <device-id> --dart-define=APP_ENV=staging --dart-define=API_BASE_URL="$API_BASE_URL"
```

`flutter run` запускает public read-only runtime. Tests не выполняют сетевые запросы и не подменяют приложение fake business data.
