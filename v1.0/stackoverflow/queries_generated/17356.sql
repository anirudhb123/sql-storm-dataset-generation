SELECT p.Id AS PostId, p.Title, u.DisplayName AS OwnerDisplayName, p.CreationDate, p.ViewCount
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
WHERE p.PostTypeId = 1 -- Select only questions
ORDER BY p.CreationDate DESC
LIMIT 10;
