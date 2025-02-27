SELECT p.Id, p.Title, u.DisplayName, p.CreationDate
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
WHERE p.PostTypeId = 1 -- Assuming PostTypeId 1 represents Questions
ORDER BY p.CreationDate DESC
LIMIT 10;
