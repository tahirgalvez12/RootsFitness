import Foundation

enum FeedItem: Identifiable, Hashable {
    case exercise(Post, PostExercise, [PostMedia])
    case weight(Post, PostWeight, [PostMedia])
    case meal(Post, PostMeal, [PostMedia])
    case progressPic(Post, [PostMedia])

    var post: Post {
        switch self {
        case .exercise(let post, _, _): return post
        case .weight(let post, _, _): return post
        case .meal(let post, _, _): return post
        case .progressPic(let post, _): return post
        }
    }

    var media: [PostMedia] {
        switch self {
        case .exercise(_, _, let media): return media
        case .weight(_, _, let media): return media
        case .meal(_, _, let media): return media
        case .progressPic(_, let media): return media
        }
    }

    var id: UUID { post.id }
}
