# common

- user_id: !bigint?
    - ユーザーID
- user_agent: !string 1000
    - ユーザーエージェント
- os_version: !string 32
    - iOSバージョン
- application_version: !string 32
    - アプリケーションバージョン
- time_zone: !string 64
    - タイムゾーン(Asia/Tokyoなど)
- [obsolete] user_status: !string 32
    - example1, example2, example3
- device_kind: DeviceKind
    - 端末の種類
    - phone, tablet, unknown
- device_model: !string 16
    - 端末のモデル
    - 実機だと「iPhoneXX,X」または「iPadXX.X」形式
