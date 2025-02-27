SELECT p.Id, p.Title, u.DisplayName, p.CreationDate, p.Score
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
WHERE p.PostTypeId = 1 -- Questions only
ORDER BY p.CreationDate DESC
LIMIT 10;
