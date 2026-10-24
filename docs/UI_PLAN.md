# PickAFrame — Unified Frame Catalogue (`Screen c`) UI 开发计划

> **关于 `docs/UI_PLAN.md` 可以删除吗？**
> **完全可以随时 Delete！** 它只是方便你在编辑器里阅读的计划草稿，没有任何代码依赖它。等我们做完 UI 提交代码给队友前，可以直接把 `docs/UI_PLAN.md` 删掉。

---

## 1. 页面定位与文件结构规划（不动队友代码）

根据 `docs/ARCHITECTURE.md` 的分工表：
- **`Screen c` — Unified Frame Catalogue (search, filters, grid)** 由 **Jasper（你）** 负责。
- 配色继续沿用 `lib/app/app_theme.dart` 的 **浅白画布 (`#FFFFFF` / `#F8FAFC`) + 5色冷灰蓝板 (`#090A0C`, `#1E2229`, `#2C3E50`, `#4B5563`, `#71717A`)**。

### 拟新增的文件结构
```text
PickAFrame/lib/
├── views/
│   ├── welcome_screen.dart                  # [已完成] Screen a: Landing Page
│   └── catalog/
│       └── catalog_screen.dart              # [新增] Screen c: Unified Frame Catalogue 主页面
└── widgets/
    └── catalog/                             # [新增] Catalogue 模块化子组件
        ├── catalog_header_section.dart      # 顶栏 (<- Catalog + 头像) + 品牌行 + 三段式 Tab + 搜索框
        ├── catalog_filter_sort_bar.dart     # [青色圈] Filters 按钮 + 筛选标签 Chips + Sort 下拉栏
        ├── moulding_grid_card.dart          # 2x2 画框网格卡片 (已去掉红圈冗余信息)
        ├── active_exhibition_banner.dart    # Active Exhibition: KL Spring Show 虚线横幅
        ├── workshop_map_placeholder.dart    # KL Workshop Map Directory 占位卡片 (供队友后续替换)
        └── catalog_bottom_nav_bar.dart      # 底部导航栏 (Home · Catalog · [+] · Exhibit · Orders)
```

---

## 2. 按你的 4 张截图逐项拆解（红圈删除 vs. 青圈保留按钮）

### ① 顶部导航与搜索区（对应图 2）
- **【红色圈 — 全部移除】**：
  1. 移除 `Catalog` 上方的 `SPEC 01 // RAW` 小字。
  2. 移除右上角头像左边的「筛选调节图标」。
  3. 移除 `Pick A-Frame` 品牌栏右侧的 `/ CATALOG ENGINE`、`KL WORKSHOPS` 标签以及 `@curator`。
- **【保留并实现的 UI】**：
  1. **顶栏**：左侧返回箭头 `<-` + 粗体 `Catalog` 标题 + 右侧深色圆形用户头像按钮 (`#090A0C`)。
  2. **品牌栏**：仅保留左侧 `[A] Pick A-Frame (PRECISION FRAMING)` Logo。
  3. **三段式切换栏 (Segmented Tabs)**：`[ Catalog ]`（当前选中白底卡片）、`Map (KL)`、`Drafts (12)`。
  4. **搜索框**：`Search mouldings, vendors, ID...`。

### ② 筛选与排序区（对应图 2 青色圈）
- **【青色圈 — 先把 Button 样式做出来，预留点击回调等你讲 Function】**：
  1. **`Filters` 主按钮**：深色实心按钮 `[ Filters (2) ]`（底色 `#090A0C`，带白色圆形数字角标 `2`）。
  2. **横向可滚动的已选筛选标签 (Filter Chips)**：如 `[ Mat: Wood X ]`、`[ Max: < RM40/m X ]`。
  3. **`Sort` 排序栏**：全宽白底边框按钮 `[ Sort: Newest v ]`。

### ③ 2×2 画框网格卡片 `MouldingGridCard`（对应图 3）
- **【红色圈/红线 — 全部拿走】**：
  1. 移除图片左上角的白色标签（`KL READY`、`POPULAR`、`MUSEUM`）。
  2. 移除卡片中间的型号编码与槽深（`MLD-0142`、`rebate 14mm` / `rebate 11mm` / `rebate 22mm` / `rebate 12mm`）。
  3. 移除标题下方的材质副标题（`Natural grain · Hardwood`、`Gallery slim · Matte anodized` 等）。
- **【保留在卡片上的核心元素】**：
  1. **上半部方形预览框**（浅蓝灰底 `#EEF2F7` + 45° 对角虚线 + 中央画框截面示意图 `35mm`/`20mm`/`50mm`/`25mm`）。
  2. **画框名称（粗体）**：`Walnut 35mm`、`Black 20mm`、`Gilded 50mm`、`Oak 25mm`。
  3. **底部价格与操作栏**：左侧 `per metre` + **`RM 38/m`**，右侧爱心按钮 + 深色方形 `[ + ]` 按钮。

### ④ 底部展览横幅、地图占位与底部导航（对应图 4 & 图 1）
1. **Active Exhibition 横幅 (`ActiveExhibitionBanner`)**：`Active Exhibition: KL Spring Show` + `[ Inspect Draft ]` 按钮。
2. **KL Workshop Map Directory 占位卡片 (`WorkshopMapPlaceholder`)**：带 `[CLOSE]` 按钮与吉隆坡地图视觉占位（`9 VERIFIED WORKSHOPS CONNECTED`），方便队友后续替换成真地图。
3. **底部导航栏 (`CatalogBottomNavBar`)**：`Home` · `Catalog` · `[+]` · `Exhibit` · `Orders`。
