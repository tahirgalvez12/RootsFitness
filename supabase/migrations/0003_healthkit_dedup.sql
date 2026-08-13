-- Prevents a HealthKit workout from being imported as a post more than once,
-- even if sync somehow runs twice concurrently (app-side filtering alone
-- isn't race-safe). Partial index: existing rows are all healthkit_uuid IS
-- NULL, so this is purely additive and safe to run against live data.
create unique index post_exercise_healthkit_uuid_unique
  on public.post_exercise (healthkit_uuid)
  where healthkit_uuid is not null;
