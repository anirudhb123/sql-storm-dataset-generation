SELECT p.Id, p.Title, p.CreationDate, u.DisplayName AS OwnerDisplayName
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
WHERE p.PostTypeId = 1 -- Only questions
ORDER BY p.CreationDate DESC
LIMIT 10; -- Get the 10 most recent questions
