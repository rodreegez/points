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

3. Register the `/ping` slash command:

   ```bash
   bundle exec ruby script/register_slash_commands.rb
   ```

## Routes

- `GET /up` health check
- `POST /interactions` Discord interactions endpoint

## Deploy

1. Configure Kamal secrets, including Discord credentials and `GHCR_TOKEN`.
2. Point the Discord interactions URL at your deployed `/interactions` endpoint.
3. Deploy with Kamal.
