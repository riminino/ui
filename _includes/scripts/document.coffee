#
# Loop Document FORMs
# --------------------------------------
$('form.document[data-file]').each ->
  form = $ @
  path = url_from_datafile form

  #
  # EVENTS
  # --------------------------------------

  # ADD PROPERTY
  form.on 'click', 'a[data-add="item"]', ->
    form.find('[inject]').append form_create_item form
    return # End add item event

  # Reset
  form.on 'reset', ->
    # Remove appended items and items adder, reset item index
    form.find('[inject]').empty()
    form.find('[data-type=item]').remove()
    form.find('[name=index],[name=schema_type]').val ''
    # Remove focus on buttons
    form.find('[data-type=button] a').blur()
    # Remove description
    form.find('h3 + p').remove()
    # If form was editing from a csv TABLE, reset class
    $(document).find("table.csv-table[data-file='#{form.attr 'data-file'}'] tr.blink").removeClass 'blink'
    # Load schema
    if form.attr 'data-file' then form_load_schema form.attr('data-file'), 'document'
    return # end Reset handler

  # Submit
  form.on 'submit', ->

    # Check user logged is Admin (write permissions)
    if !$('html').hasClass 'role-admin'
      notification 'You need to login as `admin`', 'red'
      return # Exit submit handler if not admin
    
    #
    # Parse FORM
    # --------------------------------------
    
    # Exit handler if form is an empty object
    if !Object.keys(form.serializeJSON()).length then return
    
    # Schema.type: 0 for object, 1 for array items
    schema_type = form.find('a[href="#add-item"],[name=schema_type][value=array]').length

    # Set file and url for an object
    file = JSON.stringify form.serializeJSON()
    document_url = "#{path}.json"

    # For array items, rewrite file and url
    if schema_type
      # Assemble CSV
      head = []
      rows = []
      # Loop form Item DIVs (rows)
      form.find('.item').each (i, row) ->
        rows[i] = []
        # Loop form items INPUT fields
        $(@).find(':input').each (j, field) ->
          head[j] = $(field).attr 'name'
          rows[i].push $(field).val()
          return # End INPUT fields loop
        return # End item DIVs loop
      # Prepare file and url
      head_csv = head.join ','
      rows_csv = (row.join(',') for row in rows).join '\n'
      file = [head_csv, rows_csv].join('\n')
      document_url = "#{path}.csv"

    # Start checking file existence
    form.attr 'disabled', ''

    # Check if document exist
    get_document = $.get document_url
    get_document.fail (request, status, error) ->
      # File don't exist
      if error is 'Not Found'
        # Prepare commit
        load =
          message: 'Create document'
          content: Base64.encode file
        # Commit new file
        notification load.message
        put = $.ajax document_url,
          method: 'PUT'
          data: JSON.stringify load
        put.done (data) ->
          notification 'Document created', 'green'
          # Save new SHA for future deletes
          stored_data =
            sha: data.content.sha
            content: Base64.encode file
          # Save data for the future
          cache document_url, stored_data
          # Update other elements
          update_csv "#{form.attr 'data-file'}", stored_data
          form.trigger 'reset'
          return # End document created
        put.always -> form.removeAttr 'disabled'
      else form.removeAttr 'disabled'
      return # End file don't exist case
    
    # File present, overwrite with SHA reference
    get_document.done (data) ->
      data = cache document_url, data

      # Type ARRAY
      # Prepare new file with updated/appended row
      if schema_type
        # Decode old file
        csv_array = Base64.decode(data.content).split '\n'
        # Update old head
        csv_array[0] = head_csv
        # Assemle csv, prepend or update row
        if !form.find('[name=index]').val()
          # Append new item(s)
          csv_array.push rows_csv
        else
          # Update indexed row
          csv_array[+form.find('[name=index]').val()] = rows_csv
        file = csv_array.join('\n')

      # Type OBJECT and ARRAY
      # Prepare commit
      load =
        message: 'Edit document'
        sha: data.sha
        content: Base64.encode file
      # Commit edited file
      notification load.message
      put = $.ajax document_url,
        method: 'PUT'
        data: JSON.stringify load

      # Document edited handler
      put.done (data) ->
        notification 'Document edited', 'green'
        # Save new SHA and data for the future
        stored_data =
          sha: data.content.sha
          content: Base64.encode file
        cache document_url, stored_data

        # Reset CSV elements
        update_csv "#{form.attr 'data-file'}", stored_data
        # Reset form
        form.trigger 'reset'
        return # End document update
      put.always -> form.removeAttr 'disabled'
      return # End update file

    return # End SUBMIT

  return # End form loop
{%- capture api -%}
## Document

Manage a document FORM from a schema of `type=array`.  
Needs [document]({{ 'docs/widgets/#document' | absolute_url }}) widget.

**FORM**

- Class `document`
- Attribute `data-file`: URI-reference of the schema to load (no extension)
{%- endcapture -%}