# sumo_shared

Non-UI Dart code shared by the three Sumo Flutter apps — `provider`
(`sumo_slideon`), `company` (`sumo_company`) and `super-app` (`sumo`).
Each file here used to exist as an identical copy inside two or three of the
apps (tech debt h18, phase 1).

## Rules for what goes in

- Pure Dart / `flutter/services` only — **no GetX, no routes, no widgets,
  no app imports** (`package:sumo_slideon/...` etc. must never appear here).
  Widgets belong in `zero_ui` (repo root).
- Only code whose behaviour is identical in every app that uses it. If one
  app needs different behaviour, that app keeps its own copy.
- Every file has a test under `test/` mirroring its path.

## Layout

| Folder | What |
|---|---|
| `lib/utils/` | formatters, validators, `jwt_decoder`, `json_loader`, `pretty_print`, `SessionGuard` |
| `lib/constants/` | `MovingType`, `PinVerifyMode` |
| `lib/models/` | JSON models (`error/`, `location/`, `notification/`, `dropdown/`, …) |
| `lib/app_guide/` | app-guide script parsing + WebP frame timeline (logic only) |

Import files directly, e.g.
`import 'package:sumo_shared/models/error/api_error_model.dart';` —
there is no barrel file on purpose (several models declare same-named
classes such as `LicenseType`, `Status`, `Type`).

## Develop

```bash
cd packages/sumo_shared
fvm flutter pub get
fvm flutter analyze
fvm flutter test
```

Consumed via git dep with `path: packages/sumo_shared` and the same `ref`
tag as `zero_ui`.
