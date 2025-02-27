
SELECT p.Id, p.Title, p.Score, u.DisplayName
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
WHERE p.PostTypeId = 1
GROUP BY p.Id, p.Title, p.Score, u.DisplayName
ORDER BY p.Score DESC
OFFSET 0 ROWS
FETCH NEXT 10 ROWS ONLY;
