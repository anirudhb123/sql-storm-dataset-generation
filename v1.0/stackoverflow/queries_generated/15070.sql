SELECT u.DisplayName, p.Title, p.CreationDate
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
WHERE p.PostTypeId = 1 -- Fetching only Questions
ORDER BY p.Score DESC
LIMIT 10;
