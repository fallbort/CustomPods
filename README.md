# CustomPods

ShareAndPay 模块流程:
1.注册第三方平台账号
2.注册友盟平台账号
3.配置LSApplicationQueriesSchemes

<key>LSApplicationQueriesSchemes</key>
<array>
<!--微信 URL Scheme白名单-->
<string>wechat</string>
<string>weixin</string>
<string>weixinULAPI</string>
<string>weixinURLParamsAPI</string>


<!-- QQ、Qzone URL Scheme白名单-->
<string>mqqopensdklaunchminiapp</string>
<string>mqqopensdkminiapp</string>
<string>mqqapi</string>
<string>mqq</string>
<string>mqqOpensdkSSoLogin</string>
<string>mqqconnect</string>
<string>mqqopensdkapi</string>
<string>mqqopensdkapiV2</string>
<string>mqqopensdkapiV3</string>
<string>mqqopensdkapiV4</string>
<string>tim</string>
<string>timapi</string>
<string>timopensdkfriend</string>
<string>timwpa</string>
<string>timgamebindinggroup</string>
<string>timapiwallet</string>
<string>timOpensdkSSoLogin</string>
<string>wtlogintim</string>
<string>timopensdkgrouptribeshare</string>
<string>timopensdkapiV4</string>
<string>timgamebindinggroup</string>
<string>timopensdkdataline</string>
<string>wtlogintimV1</string>
<string>timapiV1</string>

<!--新浪微博 URL Scheme白名单-->
<string>sinaweibohd</string>
<string>sinaweibo</string>
<string>sinaweibosso</string>
<string>weibosdk</string>
<string>weibosdk2.5</string>
<string>weibosdk3.3</string>


4.配置URL Scheme
微信：
微信appKey    wxdc1e388c3822c80b
QQ:
需要添加两项URL Scheme： 1、”tencent”+腾讯QQ互联应用appID 2、“QQ”+腾讯QQ互联应用appID转换成十六进制（不足8位前面补0）

如appID：100424468 1、tencent100424468 2、QQ05fc5b14
QQ05fc5b14为100424468转十六进制而来，因不足8位向前补0，然后加”QQ”前缀

微博：
“wb”+新浪appKey  wb3921700954

5.配置Universal link






