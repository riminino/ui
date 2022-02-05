# Dispatch
updates = ->

  # Schedule next check
  setTimeout updates, 60 * 1000

  # Abort if browsing site
  if focus then return

  latest_url = github_api_url + if login.logged() then '/pages/builds' else '/commits'
  latest_build = $.get latest_url
  latest_build.done (data) ->
    data = cache data, latest_url
    latest_date = if login.logged()
      # Take the first 'built' build
      element = data.filter((build) -> build.status is 'built')[0]
      element.updated_at
    else data[0].commit.author.date
    # Compare latest build created_at and site.time
    console.log +new Date(latest_date) / 1000, {{ site.time | date: "%s" }}
    if +new Date(latest_date) / 1000 > {{ site.time | date: "%s" }}
      loc = window.location
      new_url = loc.origin + loc.pathname + '?latest=' + latest_date + loc.hash
      # Refresh with the latest built creation unix time on tab blur
      if !focus then window.location.href = new_url
    return # End latest callback

  return # End checks

# Start checks, pages API is for authenticated users
if '{{ site.github.environment }}' isnt 'development'
  setTimeout updates, 60 * 1000

{%- capture api -%}
## Updates

Updates are checked every minute after pageload, only if window is blurred.

**Latest build**

Compare Jekyll `site.time` with GitHub latest built `created_at`.  
If they are different and the browser tab is blurred, refresh the page.

This script is not active in `development` environment.
{%- endcapture -%}