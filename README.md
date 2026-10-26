# Subliminal Audio Player

一个面向本地显化音频播放的 Flutter 音乐播放器。  
支持本地音频导入、歌曲播放、歌单管理、迷你播放栏和全屏播放页。

---

## 功能特性

- 本地音频导入
    - 使用系统文件选择器导入 MP3 / MP4 等音频
    - 自动读取文件名
- 歌曲播放
    - 播放 / 暂停
    - 上一首 / 下一首
    - 播放进度
    - 设置单曲播放时长
- 歌单管理
    - 创建歌单
    - 歌单内添加歌曲
    - 播放歌单
- 全局播放状态
    - 迷你播放栏常驻
    - 全屏播放页
- 本地持久化
    - 保存导入歌曲
    - 保存歌单与歌曲关系
    - 保存设置
- 音频会话
    - 音频焦点管理
    - 后台播放基础支持

---

## 技术栈

| 模块 | 技术 |
|---|---|
| 框架 | Flutter |
| 语言 | Dart |
| 播放内核 | audioplayers |
| 文件导入 | file_picker |
| 状态管理 | provider |
| 本地持久化 | shared_preferences |
| 音频会话 | audio_session |
| 过渡/平滑播放 | sautiflow |

---

![SubPlayer 界面](lib\paint\主页.png)

![SubPlayer 界面](lib\paint\播放页.png)
