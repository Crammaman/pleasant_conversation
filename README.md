# Pleasant Conversation

A small Rails app for managing conversation queues. Users can have a Profile
with configurable Questions (text, select, or radio); each profile has a
current Queue of Conversations whose Answers snapshot the question text at
creation time.

- Rails 8.1 / Ruby 3.4, SQLite database
- Bulma CSS (vendored, no build step), vanilla JS only — no JS framework

## Running locally

```sh
bundle install
bin/rails db:setup   # creates, migrates, and seeds
bin/rails server
```

Log in at http://localhost:3000 with `admin` / `password123` (seeds also
create `alice` and `bob`, same password, each with a profile, questions, and
a current queue with example conversations).

## Running with Docker

```sh
docker-compose up --build   # or: docker compose up --build
```

The app is served on http://localhost:3000. The SQLite databases live in a
named volume (`sqlite_data`) so data persists across restarts; the entrypoint
runs `db:prepare` (migrating and seeding on first boot). The credentials
master key is mounted from `config/master.key`. Set `FORCE_SSL=true` when
deploying behind a TLS-terminating proxy.

## Tests

```sh
bin/rails test
```

## Domain notes

- The queue model is `ProfileQueue` (table `queues`) because Ruby reserves the
  `Queue` constant; associations still read `profile.queues`,
  `conversation.queue`.
- Question options for select/radio types are stored in the `config` JSON
  column as `{"options" => [...]}`.
- Conversations soft-delete: state is one of `pending`, `in_progress`,
  `finished`, `deleted`; only one conversation per queue may be in progress
  at a time.
- Answers keep a `question_text` snapshot so they still render if their
  question is later edited or deleted.
