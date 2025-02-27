SELECT p.Id, p.Title, p.Score, u.DisplayName AS OwnerName, p.CreationDate
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
WHERE p.PostTypeId = 1  -- Only selecting Questions
ORDER BY p.CreationDate DESC
LIMIT 10;
