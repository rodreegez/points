# Points

Minimal Discord interactions app built with Rack, Puma, and Kamal.

## Local setup

1. Install gems:

   ```bash
   bundle install
   ```

2. Start the app:

   ```bash
   bundle exec rackup
   ```

3. Run database migrations:

   ```bash
   bundle exec ruby script/migrate.rb
   ```

4. Register the `/ping` slash command:

   ```bash
   bundle exec ruby script/register_slash_commands.rb
   ```

## Routes

- `GET /up` health check
- `POST /interactions` Discord interactions endpoint

## Database

Set `DATABASE_URL` before running migrations or future points features.

Example:

```bash
export DATABASE_URL='postgres://points_app:...@172.17.0.1:5432/points_production'
bundle exec ruby script/migrate.rb
```

## Deploy

1. Configure Kamal secrets, including `DATABASE_URL`, Discord credentials, and `GHCR_TOKEN`.
2. Point the Discord interactions URL at your deployed `/interactions` endpoint.
3. Deploy with Kamal.
