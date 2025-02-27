SELECT p.Id, p.Title, u.DisplayName, p.ViewCount, p.CreationDate
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
WHERE p.PostTypeId = 1 -- Retrieving only Questions
ORDER BY p.ViewCount DESC
LIMIT 10;
