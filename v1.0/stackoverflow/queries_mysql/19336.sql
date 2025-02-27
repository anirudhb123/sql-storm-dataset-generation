
SELECT u.DisplayName, p.Title, p.CreationDate, p.ViewCount
FROM Posts AS p
JOIN Users AS u ON p.OwnerUserId = u.Id
WHERE p.PostTypeId = 1
GROUP BY u.DisplayName, p.Title, p.CreationDate, p.ViewCount
ORDER BY p.ViewCount DESC
LIMIT 10;
