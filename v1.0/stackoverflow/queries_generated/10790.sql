EXPLAIN ANALYZE
SELECT p.Id, p.Title, p.CreationDate, p.ViewCount, u.DisplayName, COUNT(c.Id) AS CommentCount
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN Comments c ON p.Id = c.PostId
WHERE p.PostTypeId = 1 -- Select only questions
GROUP BY p.Id, u.DisplayName
ORDER BY p.ViewCount DESC
LIMIT 100;
