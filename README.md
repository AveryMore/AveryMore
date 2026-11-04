<div align="center">

<img src="https://raw.githubusercontent.com/AveryMore/AveryMore/v0.1.0/apps/macos/AIEPopup/Resources/AppIcon.png" width="96" alt="AveryMore Logo">

# AveryMore

**Find everything. Make more of it.**  
**找得到，更用得好。**

Local-first AI for your files.

Search · Understand · Rediscover · Reuse

[官网](https://averymore.github.io/) · [下载 macOS 版](https://github.com/AveryMore/AveryMore/releases/tag/v0.1.0) · [安装指南](https://github.com/AveryMore/AveryMore/blob/v0.1.0/docs/INSTALL.md) · [反馈问题](https://github.com/AveryMore/AveryMore/issues)

macOS 14+ · Apple Silicon · MIT 开源

</div>

## 记得内容，就能开始找

你记得文件的内容，却忘记了名字；记得大概的画面，却想不起保存的位置。

AveryMore 是为 Mac 打造的本机优先 AI 文件工具：找回被遗忘的文件，也让已有内容继续发挥价值。不必每次把文件重新交给大模型读一遍，也不必等所有文件分析完才开始搜索。

## 可以用它做什么

- **语义搜索。** 只记得用途，也能开始找。输入「退租前怎么通知房东」这样的自然表达，从已有文档中寻找相关内容，再打开原文核对。
- **自然语言找图。** 描述「歪着的那座白塔」这样的画面，不必先想起地名、拍摄日期或图片文件名。
- **视频内容检索。** 记得「茶田里的航拍公路」，就从场景入手；有时间定位的命中可以跳到相关位置继续看。
- **后台 AI 理解。** 开启本机深度理解后，设备保持运行时逐步分析文件，保存摘要供以后复用。设置页分别展示文件解析、内容识别、语义索引和深度理解的进度。
- **咔哒一下。** 给未完成的草稿、速写或旧材料一个下文：选择四个建议方向之一，或输入自己的要求，生成新版本，再与原件并排比较、继续修改。原件默认保留。

搜索结果指向已有文件，并提供可用的命中片段、页码或时间位置；它们不是临时编出的答案。上面的查询示例来自内部测试资料，不代表安装包附带这些文件。

## 看看实际界面

![AveryMore 搜索界面，使用合成旅行计划样例](https://raw.githubusercontent.com/AveryMore/AveryMore/v0.1.0/docs/demo/poster.png)

[观看 8 秒 Demo](https://github.com/AveryMore/AveryMore/blob/v0.1.0/docs/demo/demo.mp4) · [查看动态演示](https://raw.githubusercontent.com/AveryMore/AveryMore/v0.1.0/docs/demo/demo.gif)

现有公开素材由应用界面与合成样例渲染，展示搜索、方向选择和新旧版本对比，不含私人文件。演示经过剪辑，不代表模型的实际响应时间；界面以所展示版本为准。

## 搜索怎样工作

AveryMore 把快速检索、提前积累的文件理解和相关性精排结合起来。先给出可用结果，再异步增强排序。

| 组件 | 作用 |
|---|---|
| FTS5 | 检索文件名、原文及已提取的 OCR、转录文字等关键词证据 |
| EmbeddingGemma | 在本机编码和检索文本、图片及视频采样帧等内容的语义向量 |
| RRF | 融合关键词与语义召回的候选排名，形成最多 30 条的快速首屏 |
| Qwen3-VL 8B | 在后台理解文件、形成摘要，不在每次搜索时重新分析文件 |
| DeepScan | 将当前文件版本的有效摘要编码为独立向量，补充原始内容召回 |
| 本地 BGE | 可选精排；当前 Build 2 默认开启，对融合候选中的 Top5 进一步判断相关性 |

首屏不等待 DeepScan 或 BGE。已有 DeepScan 摘要向量补充召回后，由本地 BGE Top5 精排，一次发布增强排序；失败或超时保留首屏，查询变化后不发布旧结果。详见[当前版本说明](https://github.com/AveryMore/AveryMore/releases/tag/v0.1.0)。

“你休息时，AI 继续理解”指设备仍在运行、相应后台功能已开启，不是电脑休眠或关机后继续计算。首次分析需要时间，也会占用本机资源。

## 探索性内部测试

在同一台 M4 Mac mini、同一份 467 文件库上，AveryMore v0.1.0 Build 2 完整增强搜索与 DigUp 0.6.2 默认搜索的 **65 道共同覆盖查询**中：

| 工具 | Top1 命中率（正确文件排在第一） |
|---|---:|
| AveryMore | **87.7%（57/65）** |
| DigUp 0.6.2 | 67.7%（44/65） |

双方 Top10 均为 96.9%（63/65），本轮差异主要在于正确结果能否排得更靠前。**这是探索性内部测试，使用已有题库，不代表普适准确率或所有场景领先。**

<details>
<summary>测试口径与限制</summary>

- 整轮 80 题单次运行，包含 54 题日常、22 题模糊记忆、4 题无答案。上述 65 题是 76 道有答案查询中的共同覆盖子集，无答案题不计入命中率。
- 并非独立新测试集，所有有答案查询均有 DeepScan 覆盖。指标按冻结指定目标统计，18 题合理替代答案未事后计入；相关性标注未经独立人工复核。
- 隔离测试库初始化清理了 10 条旧原文向量，影响未量化；结果不能直接推广到其他设备、新文件库或未完成理解的文件。

</details>

## 下载与安装

当前仍为**体验版（v0.1.0 Build 2）**，支持 **macOS 14+、Apple Silicon（M 系列）**。完整 DMG 不支持 Intel Mac。EmbeddingGemma、BGE 模型及便携运行环境已随包提供；Qwen3-VL 内容理解模型按所选方案单独下载，需要额外存储空间。使用下载版无需安装 Python 或开发工具。

1. 从[官方 Release](https://github.com/AveryMore/AveryMore/releases/tag/v0.1.0)下载 `AI-Everything-0.1.0-arm64.dmg` 和 `SHA256SUMS`，核对下载完整性。
2. 打开 DMG，将应用拖到「应用程序」。**当前安装包内仍使用旧名称 AI Everything**；本 README 使用品牌名 AveryMore。
3. 按引导授权一个资料夹，建议先从小型资料夹开始。文件清单、内容识别、向量与深度理解会逐步就绪。
4. 按 `⌥ Space` 唤起搜索；`Return` 打开文件，`Space` 预览，`⌘ Return` 在 Finder 中定位。

在 DMG 与校验文件所在目录执行：

```sh
shasum -a 256 -c SHA256SUMS
```

### 首次打开：在系统设置中允许体验版运行

当前体验版尚未获得 Developer ID 签名和 Apple 公证。首次打开若提示“无法验证开发者”或“Apple 无法检查是否包含恶意软件”，请先确认下载来源和校验结果，再手动操作：

1. 从「应用程序」双击一次 **AI Everything**，关闭拦截提示。
2. 打开 ** → 系统设置 → 隐私与安全性**，向下滚动到「安全性」。
3. 找到 **AI Everything** 对应的拦截说明，点击 **「仍要打开」**。
4. 再次出现确认窗口时，点击「打开」，并按系统提示完成确认。

![macOS 隐私与安全性中的“仍要打开”按钮，Apple 官方示意图](https://cdsassets.apple.com/live/7WUAS350/images/macos/sequoia/locale/zh-cn/macos-sequoia-system-settings-privacy-and-security-open-app-anyway.png)

图片来源：[Apple 官方支持](https://support.apple.com/zh-cn/102445)。图中的“示例 App”仅为示意，实际请找到 **AI Everything**；界面可能随 macOS 版本略有不同。

这只为当前应用添加允许打开的例外，**不需要关闭系统安全保护**。若校验失败或系统明确提示检测到恶意软件，请停止安装。

## 本机优先，云端边界清楚

默认搜索、本机 OCR、Gemma 向量、本地 BGE 和已安装的 Qwen3-VL 理解均在 Mac 上执行；索引、向量和分析结果保存在本机。基础搜索不要求注册账号或配置 API Key。下载模型需要网络。

**「咔哒一下」使用云端模型，需要自行配置 OpenRouter API Key。** 点击后进入文件理解与方向建议流程时，所选正文、图片、摘录等内容就可能上传；后续生成、修改和版本总结也可能调用云端。请仅使用允许上传的资料，费用和数据处理政策以 OpenRouter 及相应模型服务为准。

Jev 是独立可选的云端搜索判断，默认关闭。只有明确选择并配置 Key 后才会发送查询与候选内容；本地 BGE 失败不会自动回退云端。旧开发版升级用户还应核对云端 QuickScan 兼容配置，详见[隐私说明](https://github.com/AveryMore/AveryMore/blob/v0.1.0/docs/PRIVACY.md)。

## 已知限制

- 搜索质量取决于文件格式、识别与索引覆盖，阶段可用不代表全部内容已处理。视频采用采样与分段定位，不能保证覆盖每个画面或提供逐词时间戳。
- 大批量索引与 8B 理解可能占用较多内存和计算资源；速度随设备和文件规模变化。
- 再创作与候选建议仍在完善，可能理解错误或生成不准确内容，使用和发布前需要人工检查。
- 当前尚未实现完整 App Sandbox 隔离；API Key 保存在本机权限受限文件中，尚未使用 Keychain。更多边界见[隐私说明](https://github.com/AveryMore/AveryMore/blob/v0.1.0/docs/PRIVACY.md)。

## 开源与贡献

应用基于 **SwiftUI + AppKit + SQLite / GRDB**，源码采用 [MIT License](https://github.com/AveryMore/AveryMore/blob/v0.1.0/LICENSE)。模型、运行时与其他依赖分别遵循各自许可证，见[第三方说明](https://github.com/AveryMore/AveryMore/blob/v0.1.0/THIRD_PARTY_NOTICES.md)。

欢迎通过 [Issues](https://github.com/AveryMore/AveryMore/issues)反馈问题，或按[贡献指南](https://github.com/AveryMore/AveryMore/blob/v0.1.0/CONTRIBUTING.md)提交 Pull Request。源码构建与验证见[开发指南](https://github.com/AveryMore/AveryMore/blob/v0.1.0/docs/DEVELOPMENT.md)。请提供最小复现步骤和可公开的合成样例，不要上传私人文件、API Key、完整日志或数据库。
