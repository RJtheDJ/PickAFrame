# PickAFrame — UI 开发计划与架构指南 (UI Implementation Plan)

> **零侵入原则（不动队友代码）**：所有 `models/`、`rendering/`、`repositories/`、`shaders/`、`services/`、`data/` 以及现有的 `views/editor_screen.dart`、`views/artwork_crop_screen.dart` 均**保持原样不修改**。你的 UI 代码将作为独立的视图层接入。

---

## 1. 你的 UI 文件结构应该长什么样？（应该放哪里 & 怎么开发）

项目遵循 **MVVM + Repository** 架构（定义在 `docs/ARCHITECTURE.md`）。作为负责 **UI / App Shell / Navigation** 的成员，你的开发目录规划如下：

```text
PickAFrame/lib/
├── main.dart                          # [仅改1行] 将 home: EditorScreen() 改为 WelcomeScreen() 或 AppShell
├── app/
│   ├── app_dependencies.dart          # [队友代码，不动] 提供 AppScope.of(context)
│   └── app_theme.dart                 # [新增 - 你的文件] 集中管理你的 Coolors 色板、字体与全局组件样式
├── views/                             # [你的主战场 - 页面级 UI]
│   ├── editor_screen.dart             # [队友代码，不动] 核心画框编辑器
│   ├── artwork_crop_screen.dart       # [队友代码，不动] 透视裁切页
│   └── welcome/                       # [新增 - 你的文件夹]
│       └── welcome_screen.dart        # [新增] 第一张图：Landing Page (Welcome & Discovery)
└── widgets/                           # [你的主战场 - 可复用 UI 组件]
    ├── frame_renderer.dart            # [队友代码，不动]
    ├── editor/                        # [队友代码，不动]
    └── welcome/                       # [新增 - 你的文件夹] Landing Page 拆分出的子组件
        ├── top_spec_bar.dart          # 顶部 SPEC // S1 状态栏 + Logo + EN/BM 切换 + Log in
        ├── hero_staging_card.dart     # 虚线框 1:1 预览占位 + [+ UPLOAD YOUR ARTWORK] + Google/Email 按钮
        ├── workflow_steps_section.dart# SECTION 2 // How it works (1. Upload, 2. Design, 3. Order)
        ├── workshop_carousel.dart     # Featured KL framing workshops 横向卡片列表
        ├── venue_cta_banner.dart      # For galleries & frame shops 注册横幅
        └── welcome_footer.dart        # 底部链接 + APU Research Prototype 版权说明
```

### 你应该怎样开发（开发规范）：
1. **绝不直接 import `firebase_*` 包**：所有数据获取统一通过 `final deps = AppScope.of(context);` 调用接口（如 `deps.auth`、`deps.vendors`、`deps.drafts`）。
2. **单位转换**：所有底层 Model 的尺寸都是毫米（`mm`），UI 显示时调用 `lib/models/units.dart` 里的辅助函数或按 wireframe 显示规格。
3. **跳转到队友的编辑器**：当用户在 Landing Page 点击上传或试用时，直接通过 `Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditorScreen()))` 跳转，完全不需要改动 `EditorScreen` 内部逻辑。

---

## 2. 队友代码模块详解（只读不改，帮你快速理解如何对接）

### ① `lib/models/`（纯数据模型层）
所有数据结构都是纯 Dart 类，带 `toJson()` / `fromJson()`，你在 UI 层只需要读取它们的属性：
- **`vendor.dart` (`Vendor`)**：代表一家吉隆坡画框工坊（用于你 Landing Page 的 *Featured KL framing workshops*）。包含字段：`id`、`ownerUid`、`name`（店名）、`address`（地址）、`latitude`/`longitude`（经纬度）、`phone`、`specialties`（标签列表，如 `["Museum Glass", "Bulk Tiers"]`）、`acceptsBulkOrders`。
- **`user_profile.dart` (`UserProfile` & `UserRole`)**：当前登录用户的信息，角色枚举 `UserRole` 分为 `artist`、`galleryOwner`、`frameShopOwner`。
- **`frame_design.dart` / `moulding.dart` / `mat_spec.dart`**：保存画框宽度、材质、卡纸（Mat）四周边距、双层卡纸颜色等物理参数（全以 `mm` 为单位）。
- **`draft.dart` & `order.dart`**：用户的保存草稿与发给工坊的订单（包含生产阶段 `OrderStage`：Cut -> Assembled -> Glazed -> Ready）。

### ② `lib/repositories/`（数据仓库接口与实现）
将 UI 与 Firebase 隔离的桥梁，通过 `AppScope.of(context)` 访问：
- **`auth_repository.dart`**：提供 `watchUser()`（实时监听登录状态）、`signInWithGoogle()`、`signInWithEmail()`、`registerWithEmail()`、`setRole()`、`signOut()`。队友已经在 `firebase_auth_repository.dart` 中写好了 Firebase 实现！你在 Landing Page 的 **"Continue with Google"** 按钮可以直接绑定 `AppScope.of(context).auth.signInWithGoogle()`。
- **`vendor_repository.dart`**：提供 `watchVendors()`（返回 `Stream<List<Vendor>>`）。你在 Landing Page 的工坊横向列表可以用 `StreamBuilder<List<Vendor>>` 监听它。
- **`draft_repository.dart` & `order_repository.dart`**：读写草稿和订单。

### ③ `lib/rendering/` & `shaders/`（2D/PBR 视觉渲染引擎）
这是引擎队友写的核心画框渲染器：
- **`shaders/frame_material.frag`**：GLSL 片段着色器（Fragment Shader），利用木材/金属的漫反射贴图（Albedo）、法线贴图（Normal Map）和粗糙度贴图（Roughness Map），根据光源角度逐像素计算实时 3D 光照高光与纹理凹凸感。
- **`shaded_frame_painter.dart` & `frame_painter.dart`**：绘制 45° 斜接角（Mitre joints）画框四边及截面阴影；若设备不支持 GPU Shader 则自动回退到 CPU 渐变绘制。
- **`mat_painter.dart` & `frame_layout.dart`**：将毫米尺寸按屏幕比例换算为像素矩形，并绘制卡纸斜切内边（Bevel）和投影。
- **`widgets/frame_renderer.dart`**：把画框、卡纸、画作组合成一个 Flutter Widget。

### ④ `lib/views/editor_screen.dart` & `artwork_crop_screen.dart`（编辑器页面）
- **`editor_screen.dart`**：上半部分展示 `FrameRenderer` 实时画框预览（带光照角度滑块、尺寸输入、添加/重裁画作、3000px 高清导出按钮），下半部分是 `FramePanel`（8种框型截面 + 材质色板）和 `MatPanel`（卡纸边距、黄金比例预设、颜色）。
- **`artwork_crop_screen.dart`**：4角透视矫正裁切器，把斜拍的画作拉正。

---

## 3. 第一阶段开发目标：Landing Page（图1 Wireframe + 图2 色板）

### 🎨 色板映射方案（提取自你的图2 `mae_colorPalette`）

| 色板序号 (左->右) | Hex 色值 | 颜色描述 | 在 Landing Page (图1) 中的应用位置 |
| :--- | :--- | :--- | :--- |
| **1. Deep Slate** | `#1E2229` | 深板岩灰 | **卡片与容器背景色**（如 How it works 步骤卡、Workshop 工坊卡片、顶部导航栏、For galleries 横幅底色） |
| **2. Obsidian Black** | `#090A0C` | 曜石深黑 | **主页面大背景 (`Scaffold` background)** 及主 CTA 按钮 `[ + UPLOAD YOUR ARTWORK ]` 填充底色 |
| **3. Prussian Navy** | `#2C3E50` | 普鲁士蓝灰 | **强调色 / 徽章底色 / 重点边框**（如 `● PRECISION STAGING SYSTEM` 胶囊背景、`A3 PROFILE · MAT: 50mm` 标签、步骤 `1` `2` `3` 徽章、工坊 Specialty 标签底色） |
| **4. Cool Charcoal** | `#4B5563` | 冷炭灰 | **分割线、虚线框与次级边框**（如 `SCALE: 1:1 REAL-TIME` 外圈工业风虚线框、卡片 1px 描边、Outlined 按钮边框） |
| **5. Muted Zinc** | `#71717A` | 柔和锌灰 | **次要文字、工业编码与说明文字**（如顶部 `SPEC // S1 · WELCOME & DISCOVERY`、副标题、`JPG, PNG, HEIC - up to 25 MB`、页脚版权文字） |
| **文字对比色 (补充)** | `#F8FAFC` / `#FFFFFF` | 纯白/亮灰白 | **主标题与正文高亮文字**（如 `Frame it. Hang it. Get it made.`、店名、按钮文字），确保在深色背景上的高可读性 |

---

## 4. ⚠️ 潜在盲点与 Pain Points（需要你确认的问题）

1. **主题明暗风格确认（Dark Mode vs. Light Mode 混搭）**：
   - 图1 Wireframe 是白底深字，而图2色板（`#1E2229`, `#090A0C`, `#2C3E50`, `#4B5563`, `#71717A`）全部是**深色系**（且队友写的 `EditorScreen` 也是深色主题）。
   - **问题**：你希望 Landing Page 整体采用**全深色主题**（以 `#090A0C` / `#1E2229` 为背景，白色文字，与 `EditorScreen` 视觉完全统一），还是保持**浅白底色**、仅把这 5 个深色用在按钮/卡片/文字/边框上？
2. **`[ + UPLOAD YOUR ARTWORK ]` 按钮的交互行为**：
   - 在不改动队友 `EditorScreen` 代码的前提下，点击 Landing Page 的 `[ + UPLOAD YOUR ARTWORK ]` 直接跳转到 `EditorScreen` 可以吗？
3. **工坊列表数据（Mock Data 兜底）**：
   - 目前 `main.dart` 里 `vendors` 使用的是 `InMemoryVendorRepository()`，启动时里面是空的。我是否在 UI 层提供一个内置的 **Fallback 展示数据**（当 `watchVendors()` 返回空列表时，自动展示图1里的 *Atelier Bangsar Woodcraft* 和 *Cheras Fine Moulding*）？
4. **未实现页面的按钮占位交互**：
   - Landing Page 上的 `Sign up with email`、`Log in`、`EN | BM`、`All (14) ->`、`[ View ]`、`[ Register your venue ]` 在第一阶段点击时，是先弹出提示（`SnackBar` / 占位弹窗），还是需要接具体页面？
