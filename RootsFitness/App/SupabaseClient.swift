import Foundation
import Supabase

enum SupabaseConfig {
    static let url: URL = {
        guard
            let host = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String,
            !host.isEmpty,
            host != "your-project-ref.supabase.co",
            let url = URL(string: "https://\(host)")
        else {
            fatalError(
                "Missing SupabaseURL. Copy RootsFitness/App/Secrets.xcconfig.template to "
                + "Secrets.xcconfig and fill in your Supabase project URL."
            )
        }
        return url
    }()

    static let anonKey: String = {
        guard
            let key = Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String,
            !key.isEmpty,
            key != "your-anon-key-here"
        else {
            fatalError(
                "Missing SupabaseAnonKey. Copy RootsFitness/App/Secrets.xcconfig.template to "
                + "Secrets.xcconfig and fill in your Supabase anon key."
            )
        }
        return key
    }()
}

extension SupabaseClient {
    static let shared = SupabaseClient(
        supabaseURL: SupabaseConfig.url,
        supabaseKey: SupabaseConfig.anonKey
    )
}
