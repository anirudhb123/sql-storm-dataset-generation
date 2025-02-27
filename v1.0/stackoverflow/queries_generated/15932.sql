SELECT p.Id, p.Title, p.Score, p.ViewCount, u.DisplayName
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
WHERE p.PostTypeId = 1 -- Only Questions
ORDER BY p.Score DESC
LIMIT 10;
