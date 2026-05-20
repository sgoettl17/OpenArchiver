-- Open Archiver — reference queries for pgAdmin (database: open_archive)
--
-- Connect to the *open-archiver* Postgres, not another project on localhost:5432.
--   • Docker Desktop pgAdmin on openarchiver_open-archiver-net: host postgres, port 5432
--   • Or host.docker.internal port 5433 (see docker-compose POSTGRES_HOST_PORT)
--
-- Body text is NOT in Postgres; it is inside .eml files at storage_path.
-- There is no body_html column. The table is archived_emails (not emails).

-- Kristie mailboxes (adjust ILIKE if needed)
SELECT user_email, ingestion_source_id, COUNT(*) AS email_count
FROM archived_emails
WHERE user_email ILIKE '%kristie%'
GROUP BY user_email, ingestion_source_id
ORDER BY email_count DESC;

-- Kristie + "grocery outlet" in subject (use Dashboard → Search for body text)
SELECT ae.id,
	ae.subject,
	ae.sender_email,
	ae.user_email,
	ae.sent_at,
	ae.storage_path
FROM archived_emails ae
WHERE ae.user_email ILIKE '%kristie%'
	AND (
		ae.subject ILIKE '%grocery outlet%'
		OR (ae.subject ILIKE '%grocery%' AND ae.subject ILIKE '%outlet%')
	)
ORDER BY ae.sent_at DESC
LIMIT 100;
