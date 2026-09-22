-- Testing-only seed data for PR sandboxes. Not used in production.
--
-- Run by the `ai.qlane.postdeploy` hook on the db service in compose.qlane.yaml,
-- which fires once the whole stack is healthy -- after listmonk's own
-- `--install` has created the schema and its two sample lists.
--
-- A realistic newsletter: a few public and private lists, and a readership
-- that includes people who have unsubscribed from some of them. Deterministic
-- UUIDs and ON CONFLICT DO NOTHING make it safe to run more than once; a failed
-- hook fails the environment, so it must never error on a re-run.

\set ON_ERROR_STOP on
BEGIN;

INSERT INTO lists (uuid, name, type, optin, description) VALUES
  ('3f6c9a10-4b2e-4d7a-9c1f-0a1b2c3d4e01', 'Weekly digest',         'public',  'single', 'A roundup of the week, every Friday.'),
  ('3f6c9a10-4b2e-4d7a-9c1f-0a1b2c3d4e02', 'Product announcements', 'public',  'double', 'Launches and major updates, a few times a year.'),
  ('3f6c9a10-4b2e-4d7a-9c1f-0a1b2c3d4e03', 'Beta testers',          'private', 'single', 'Early-access programme.')
ON CONFLICT (uuid) DO NOTHING;

INSERT INTO subscribers (uuid, email, name, status) VALUES
  ('8a2d4f60-1c3b-4e5a-8d7f-1b2c3d4e5f01', 'alex.morgan@example.com',  'Alex Morgan',  'enabled'),
  ('8a2d4f60-1c3b-4e5a-8d7f-1b2c3d4e5f02', 'priya.shah@example.com',   'Priya Shah',   'enabled'),
  ('8a2d4f60-1c3b-4e5a-8d7f-1b2c3d4e5f03', 'jordan.lee@example.com',   'Jordan Lee',   'enabled'),
  ('8a2d4f60-1c3b-4e5a-8d7f-1b2c3d4e5f04', 'sam.rivera@example.com',   'Sam Rivera',   'enabled'),
  ('8a2d4f60-1c3b-4e5a-8d7f-1b2c3d4e5f05', 'chen.wei@example.com',     'Chen Wei',     'enabled'),
  ('8a2d4f60-1c3b-4e5a-8d7f-1b2c3d4e5f06', 'maria.garcia@example.com', 'Maria Garcia', 'enabled'),
  ('8a2d4f60-1c3b-4e5a-8d7f-1b2c3d4e5f07', 'noah.brown@example.com',   'Noah Brown',   'enabled'),
  ('8a2d4f60-1c3b-4e5a-8d7f-1b2c3d4e5f08', 'taylor.kim@example.com',   'Taylor Kim',   'blocklisted')
ON CONFLICT (email) DO NOTHING;

INSERT INTO subscriber_lists (subscriber_id, list_id, status)
SELECT s.id, l.id, v.status::subscription_status
FROM (VALUES
  ('alex.morgan@example.com',  'Weekly digest',         'confirmed'),
  ('alex.morgan@example.com',  'Product announcements', 'confirmed'),
  ('priya.shah@example.com',   'Weekly digest',         'unconfirmed'),
  ('jordan.lee@example.com',   'Weekly digest',         'unsubscribed'),
  ('jordan.lee@example.com',   'Product announcements', 'confirmed'),
  ('sam.rivera@example.com',   'Weekly digest',         'confirmed'),
  ('sam.rivera@example.com',   'Product announcements', 'unsubscribed'),
  ('chen.wei@example.com',     'Product announcements', 'confirmed'),
  ('maria.garcia@example.com', 'Beta testers',          'confirmed'),
  ('noah.brown@example.com',   'Weekly digest',         'confirmed'),
  ('taylor.kim@example.com',   'Weekly digest',         'unsubscribed')
) AS v(email, list_name, status)
JOIN subscribers s ON s.email = v.email
JOIN lists l       ON l.name  = v.list_name
ON CONFLICT (subscriber_id, list_id) DO NOTHING;

COMMIT;
