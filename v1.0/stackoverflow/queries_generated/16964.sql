SELECT u.DisplayName, p.Title, p.CreationDate, p.ViewCount
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
WHERE p.PostTypeId = 1 -- Selecting only questions
ORDER BY p.ViewCount DESC
LIMIT 10;
