
SELECT p.Id, p.Title, p.CreationDate, p.ViewCount, u.DisplayName AS Owner
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
WHERE p.PostTypeId = 1
GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, u.DisplayName
ORDER BY p.CreationDate DESC
LIMIT 10;
