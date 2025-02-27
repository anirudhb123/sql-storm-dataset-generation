SELECT p.Id, p.Title, u.DisplayName, p.CreationDate, v.VoteTypeId
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN Votes v ON p.Id = v.PostId
WHERE p.PostTypeId = 1 -- Question type
ORDER BY p.CreationDate DESC
LIMIT 10;
