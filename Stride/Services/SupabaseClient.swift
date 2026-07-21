import Supabase

// Single shared SupabaseClient for the entire app.
//
// Every service that needs to talk to Supabase imports this file and
// references `supabase` directly — nothing else ever constructs its own client.
//
// The client stores the authenticated session token in the iOS Keychain
// automatically. On the next cold launch `supabase.auth.session` returns
// the stored session without requiring the user to sign in again.

let supabase = SupabaseClient(
    supabaseURL: AppConfig.supabaseUrl,
    supabaseKey: AppConfig.supabaseAnonKey
)
