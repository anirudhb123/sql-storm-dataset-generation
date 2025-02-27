SELECT p.Id, p.Title, u.DisplayName, p.CreationDate, p.ViewCount
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
WHERE p.PostTypeId = 1  -- Considering only Questions
ORDER BY p.CreationDate DESC
LIMIT 10;
