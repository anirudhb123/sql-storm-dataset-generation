
SELECT p.Title, u.DisplayName, p.CreationDate, p.Score
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
WHERE p.PostTypeId = 1 
GROUP BY p.Title, u.DisplayName, p.CreationDate, p.Score
ORDER BY p.Score DESC
LIMIT 10;
