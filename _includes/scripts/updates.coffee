# Dispatch
checks = ->

  # Check latest build
  latest_url = 
  latest_build = $.get latest_url
  latest_build.done (data) ->
    data = cache data, latest_url
    created_at = +new Date(data.created_at) / 1000
    # Compare latest build created_at and site.time
    if data.status is 'built' and created_at > {{ site.time | date: "%s" }}
      loc = window.location
      new_url = loc.origin + loc.pathname + '?created_at=' + data.created_at + loc.hash
      # Refresh with the latest built creation unix time
      notification "New build #{time_diff data.created_at} <a href='#{new_url}'>Refresh</a>"
    return # End latest callback

  # Check remote theme
  if '{{ site.remote_theme }}' isnt ''
    [remote, branch] = '{{ site.remote_theme }}'.split '@'
    ajax_data = if branch then {sha: branch} else {}
    # Get latest release
    latest_url = "{{ site.github.api_url }}/repos/#{remote}/releases/latest"
    latest_tag = $.get latest_url,
      data: ajax_data
    latest_tag.done (data) ->
      data = cache data, latest_url
      published_at = +new Date(data.published_at)
      # Compare latest release published_at with storage.repository.remote_release
      if published_at > storage.get 'repository.remote_release'
        # Update remote_release in storage
        storage.set 'repository.remote_release', published_at
        notification "Remote theme changed #{data.tag_name} #{time_diff data.published_at}"
      return # End remote TAG check

  # Schedule next check
  setTimeout checks, 60 * 1000

  return # End checks

# Start checks
if '{{ site.github.environment }}' isnt 'development' and login.logged_admin()
  setTimeout checks, 2 * 1000

{%- capture api -%}
## Updates

Updates are checked 2 seconds after pageload and then every minute (if the user is logged as `admin`).

**Latest build**

Compare Jekyll `site.time` with GitHub latest built `created_at`.  
If they are different show a notification.

**Remote theme latest release**  
Compare the remote theme latest release `published_at` with the stored one.  
If they are different show a notification.

This script is not active in `development` environment.
{%- endcapture -%}