# Grok Build — disable trace/repo uploads (belt-and-suspenders with ~/.grok/config.toml)
set -gx GROK_TELEMETRY_ENABLED 0
set -gx GROK_TELEMETRY_TRACE_UPLOAD 0