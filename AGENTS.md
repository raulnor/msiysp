# MSIYSP Running Tracker - Project Status
*M.S.I.Y.S.P. ("My Sport Is Your Sport's Punishment")*

## What's Built
- Elixir app with SQLite (WAL mode for Python sharing)
- Strava OAuth + token refresh working
- Activities schema and import (100 records synced)
- Python environment with UV set up
- Basic data validation script

## Tech Stack Decisions
- Elixir + Phoenix LiveView (eventual web UI)
- SQLite shared between Elixir (read/write) and Python (read-only) 
- UV for Python package management
- Single repo structure with /python subfolder

### Strava API Pattern
- Token stored in ~/.config/msiysp/strava_tokens.json
- Auto-refresh when expired
- Rate limiting: 100 requests per 15 min, 1000 per day

### Database Access
- Elixir: Through Ecto/Repo
- Python: sqlite3 connection to races.db with WAL mode

## Current Issues
1. Only pulling 100 activities from Strava (need pagination)
2. No visualizations yet (Python notebooks ready but empty)
