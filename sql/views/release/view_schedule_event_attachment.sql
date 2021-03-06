
CREATE OR REPLACE VIEW release.view_schedule_event_attachment AS
  SELECT
    conference_release_id,
    event_attachment_id,
    event_id,
    attachment_type,
    attachment_type_localized.name AS attachment_type_name,
    mime_type,
    mime_type_localized.name AS mime_type_name,
    filename,
    title,
    pages,
    public,
    octet_length( data ) AS filesize,
    attachment_type_localized.translated
  FROM
    release.event_attachment
    INNER JOIN attachment_type_localized USING (attachment_type)
    INNER JOIN mime_type_localized USING (mime_type, translated)
  WHERE
    event_attachment.public = TRUE
  ORDER BY title,filename
;

