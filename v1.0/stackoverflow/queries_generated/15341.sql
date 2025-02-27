SELECT p.Id, p.Title, p.Score, u.DisplayName, p.CreationDate
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
WHERE p.PostTypeId = 1 -- Only select questions
ORDER BY p.Score DESC
LIMIT 10;
