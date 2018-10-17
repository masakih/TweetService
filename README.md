# TweetService
Tweet sharing service for macOS

[![Language: Swift](https://img.shields.io/badge/Swift-4.1-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![Platform](https://img.shields.io/badge/Platform-macOS-lightgray.svg?style=flat)](https://img.shields.io/)
[![License](https://img.shields.io/github/license/masakih/MovieCapture.svg?style=flat)](https://github.com/masakih/TweetService/blob/master/LICENSE)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![GitHub release](https://img.shields.io/github/release/masakih/MovieCapture.svg)](https://github.com/masakih/TweetService/releases/latest)



# お手軽簡単にあなたのアプリケーションにTweet機能を付けましょう

お手軽簡単、数ステップであなたのアプリケーションからツイートが出来るようになります。

_動画のツイートはまだ未対応_

# 使い方

## Step 0

Twitter Appを登録。
callback URLはカスタムスキームを設定。

## Step 1

Twitter Appの登録情報から`TweetService`を生成。

```swift
class ViewController: NSViewController {
    
    private var tweetService: TweetService?
    
    override func viewDidLoad() {
    
        self?.tweetService = TweetService(callbackScheme: "customscheme",  // カスタムスキームは何でもOK
                                         consumerKey: "########",
                                         consumerSecretKey: "###############")
        self?.tweetService.delegate = self
    }
}
```

## Step 2

`TweetServiceDelegate`Protocolに準拠。

ツイートパネルのparentViewControllerとなれるNSViewControllerを返す。

```swift
extension ViewController: TweetServiceDelegate {

    func tweetSetviceAuthorizeSheetPearent(_ service: TweetService) -> NSViewController? {

        return self
    }
}
```


## Step 3

`NSSharingServicePickerDelegate`Protocolに準拠。

`sharingServicePicker(_:sharingServicesForItems:proposedSharingServices:)` で `TweetService#sharingServicePicker(_:proposedSharingServices:)`の戻り値を返す。

```swift
extension ViewController: NSSharingServicePickerDelegate {
    
    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, sharingServicesForItems items: [Any], proposedSharingServices proposedServices: [NSSharingService]) -> [NSSharingService] {
                
        return tweetService?.sharingServicePicker(items, proposedSharingServices: proposedServices) ?? proposedServices
    }
}
```

## Step 4

アクションを作ってシェアボタンに接続。

```swift
extension ViewController {

    @IBAction private func tweet(_ button: NSButton) {
        
        let items: [Any?] = [
            textField?.stringValue,
            imageView?.image,
            imageView2?.image,
            imageView3?.image,
            imageView4?.image,
            ]
        
        let picker = NSSharingServicePicker(items: items.compactMap( { $0 } ))
        picker.delegate = self
        picker.show(relativeTo: .zero, of: button, preferredEdge: .minX)
    }
}
```

以上、たったこれだけであなたのアプリケーションからツイートが出来るようになります。


# Demo.appの使い方

## TwitterKeys.swiftを作成してプロジェクトに追加する必要があります

以下を参考にしてください。

```swift
let twitterKeys: TwitterKeys = (
    "customScheme",                      // Twitter app のカスタムスキーム
    "**************",                    // Twitter app の Consumer Key (API Key)
    "********************************"   // Twitter app の Consumer Secret (API Secret)
)
```

