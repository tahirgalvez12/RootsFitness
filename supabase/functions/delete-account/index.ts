// Deletes the calling user's account entirely: their post-media storage
// objects, then the auth.users row itself (which cascades through every
// other table — profiles, posts, post_media/post_exercise/post_weight/
// post_meal rows, comments, reactions, friendships in both directions —
// via the "on delete cascade" foreign keys already in the schema).
//
// Must run server-side: deleting an auth.users row requires the service
// role key, which never ships inside the iOS app. This function verifies
// the caller's own JWT and only ever acts on that caller's own user id —
// it never accepts a user id from the request body, so there is no way
// to delete anyone else's account through this endpoint.
//
// Deploy with: supabase functions deploy delete-account

import { createClient } from "npm:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Missing Authorization header" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  // Client scoped to the caller's own JWT — used only to verify who they
  // are. All destructive calls below use the admin client instead.
  const callerClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    global: { headers: { Authorization: authHeader } },
  });

  const {
    data: { user },
    error: userError,
  } = await callerClient.auth.getUser();

  if (userError || !user) {
    return new Response(JSON.stringify({ error: "Invalid or expired session" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
  const userId = user.id;

  // 1. Delete every object under this user's post-media/{userId}/ prefix.
  //    Not covered by the DB cascade — Storage isn't a Postgres table.
  const { data: files, error: listError } = await admin.storage
    .from("post-media")
    .list(userId);

  if (listError) {
    return new Response(
      JSON.stringify({ error: `Failed to list storage objects: ${listError.message}` }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }

  if (files && files.length > 0) {
    const paths = files.map((f) => `${userId}/${f.name}`);
    const { error: removeError } = await admin.storage.from("post-media").remove(paths);
    if (removeError) {
      return new Response(
        JSON.stringify({ error: `Failed to delete storage objects: ${removeError.message}` }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }
  }

  // 2. Delete the auth user — cascades through every table referencing
  //    profiles.id (which references auth.users.id on delete cascade).
  const { error: deleteError } = await admin.auth.admin.deleteUser(userId);
  if (deleteError) {
    return new Response(
      JSON.stringify({ error: `Failed to delete account: ${deleteError.message}` }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }

  return new Response(JSON.stringify({ success: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
