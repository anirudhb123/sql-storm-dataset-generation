SELECT p.Id, p.Title, p.CreationDate, u.DisplayName 
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
WHERE p.PostTypeId = 1 -- This filters for questions
ORDER BY p.CreationDate DESC
LIMIT 10;
