-- Performance Benchmarking Query
EXPLAIN ANALYZE
SELECT p.Title, p.CreationDate, p.Score, u.DisplayName AS OwnerDisplayName, 
       COUNT(c.Id) AS CommentCount, 
       SUM(v.VoteTypeId = 2) AS UpVotes,
       SUM(v.VoteTypeId = 3) AS DownVotes
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN Comments c ON p.Id = c.PostId
LEFT JOIN Votes v ON p.Id = v.PostId
WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY p.Id, u.DisplayName
ORDER BY p.CreationDate DESC
LIMIT 100;
