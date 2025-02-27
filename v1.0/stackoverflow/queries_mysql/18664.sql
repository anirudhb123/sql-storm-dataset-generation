
SELECT u.DisplayName, p.Title, p.Score, p.CreationDate
FROM Users u
JOIN Posts p ON u.Id = p.OwnerUserId
WHERE p.PostTypeId = 1
GROUP BY u.DisplayName, p.Title, p.Score, p.CreationDate
ORDER BY p.Score DESC
LIMIT 10;
