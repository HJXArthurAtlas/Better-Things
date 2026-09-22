import SwiftUI

/// 「新建列表」弹出菜单：新建项目 / 新建区域（设计稿画板「新建列表菜单」452×232）。
struct NewListMenu: View {
    let onProject: () -> Void
    let onArea: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            row(
                icon: "circle.lefthalf.fill", tint: BT.accent,
                title: "新建项目",
                desc: "定义一个目标，然后每次完成一个待办事项。",
                action: onProject
            )
            Rectangle()
                .fill(BT.content)
                .frame(height: 1)
            row(
                icon: "shippingbox", tint: BT.teal,
                title: "新建区域",
                desc: "根据不同的责任群组您的项目和待办事项，例如家庭或工作。",
                action: onArea
            )
        }
        .frame(width: 452)
        .padding(.vertical, 14)
        .background(BT.card)
    }

    private func row(icon: String, tint: Color, title: String, desc: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(tint)
                    .frame(width: 24, height: 24)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16))
                        .foregroundStyle(BT.primary)
                    Text(desc)
                        .font(.system(size: 14))
                        .foregroundStyle(BT.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
