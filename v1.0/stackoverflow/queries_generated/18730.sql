SELECT p.Id AS PostId, p.Title, u.DisplayName AS Author, p.CreationDate
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
WHERE p.PostTypeId = 1 -- Questions only
ORDER BY p.CreationDate DESC
LIMIT 10;
