# Feature Specification: 分发（图标元信息 + dmg 打包）

**Feature Branch**: `006-distribution` | **Created**: 2026-09-21 | **Status**: Implemented
**Input**: YouTrack 卡 BT-18（应用图标与元信息）、BT-19（notarized dmg 打包）。

## User Scenarios & Testing

### User Story 1 - 应用图标与元信息（BT-18，P1）
Finder 与「关于」窗口显示正确的应用名称（Better Things）、图标（蓝底白勾）、
版本号（0.1.0）与版权信息（MIT）。

### User Story 2 - 可分发的 dmg（BT-19，P2）
`scripts/build-dmg.sh` 一键产出 `Better-Things-<版本>.dmg`；挂载后可将应用拖入
Applications 并正常启动。配置 Developer ID + notarytool 凭据后，脚本自动走
签名→公证→装订；未配置时以 ad-hoc 签名产出本机可用 dmg 并明确提示。

## Requirements

- **FR-001**: 应用 MUST 内嵌资产目录图标（AppIcon），由 `scripts/make-icon.swift` 从
  程序化绘制生成（1024×1024 主图 + 全尺寸派生）。
- **FR-002**: Info.plist MUST 含 CFBundleDisplayName / CFBundleShortVersionString (0.1.0) /
  CFBundleVersion / NSHumanReadableCopyright。
- **FR-003**: `scripts/build-dmg.sh` MUST 完成 Release 构建、签名（有 Developer ID 走
  公证装订，否则 ad-hoc 降级并提示）、hdiutil 打包。

## Success Criteria

- **SC-001**: 关于面板截图取证：图标、名称、版本、版权全部正确显示。
- **SC-002**: dmg 挂载后从卷内启动应用成功；脚本一键可重复执行。
