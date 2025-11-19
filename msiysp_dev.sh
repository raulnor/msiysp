#!/bin/bash
cd /Users/travis/Code/raulnor/msiysp
exec /opt/homebrew/Cellar/elixir/1.19.3/bin/elixir \
  --sname msiysp \
  -S mix phx.server