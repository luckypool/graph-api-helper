graph-api-helper
================

mixiのGraph API を利用するためのヘルパースクリプトです。

### install modules

carton を利用して必要なモジュールを用意します（すでに環境にある場合は cpanm 等で問題ないです）。

```
carton install
```

### synopsis

```
 perl ./helper.pl [options]

 options:
    --client    credential info (formatted json)
    --scope     scope (ex. r_profile)
    --code      authorization_code
    --token     access_token, refresh_token
    --endpoint  endpoint
```

### examples

- authorization_code を取得する url を生成

```bash
perl helper.pl --client conf/client.json --scope scope/scope.json
```

- access token を取得する場合（tokenディレクトリ以下にjsonファイルとして出力されます）

```bash
perl helper.pl --client conf/client.json --code [code]
```

- ex.) access token を利用してendpointをたたく

```bash
perl helper.pl --client conf/client.json --token token/token.json \
--endpoint http://api.mixi-platform.com/2/people/@me/@self?fields=@all
````

### config files

```javascript
// conf/client.json
{
  "client_id"     : "consumer_key",
  "client_secret" : "consumer_secret",
  "redirect_uri"  : "http://mixi.jp/connect_authorize_success.html"
}
```

```javascript
// scope/scope.json
[
  "r_profile"
]
```


