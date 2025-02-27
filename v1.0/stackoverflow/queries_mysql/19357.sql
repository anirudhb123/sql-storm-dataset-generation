
SELECT p.Title, p.CreationDate, u.DisplayName, p.ViewCount
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
WHERE p.PostTypeId = 1  
GROUP BY p.Title, p.CreationDate, u.DisplayName, p.ViewCount
ORDER BY p.ViewCount DESC
LIMIT 10;
