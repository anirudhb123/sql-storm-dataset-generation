SELECT u.DisplayName, p.Title, p.CreationDate, p.Score
FROM Users u
JOIN Posts p ON u.Id = p.OwnerUserId
WHERE p.PostTypeId = 1 -- Questions
ORDER BY p.Score DESC
LIMIT 10;
