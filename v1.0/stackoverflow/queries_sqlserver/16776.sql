
SELECT p.Id, p.Title, p.Score, p.ViewCount, u.DisplayName
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
WHERE p.CreationDate >= '2023-01-01'
GROUP BY p.Id, p.Title, p.Score, p.ViewCount, u.DisplayName
ORDER BY p.Score DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
