import SwiftUI

struct RFCommentRow: View {
    let comment: CommentWithAuthor

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            RFAvatar(username: comment.author?.username ?? "?", size: 36)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(comment.author?.username ?? "Unknown")
                        .font(.rfSubheadline)
                        .foregroundStyle(Color.rfTextPrimary)
                    Text(comment.comment.createdAt, style: .relative)
                        .font(.rfCaption)
                        .foregroundStyle(Color.rfTextSecondary)
                }
                Text(comment.comment.body)
                    .font(.rfBody)
                    .foregroundStyle(Color.rfTextPrimary)
            }
        }
    }
}
