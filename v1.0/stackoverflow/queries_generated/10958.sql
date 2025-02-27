-- Performance Benchmarking SQL Query

-- Measure the performance of retrieving posts with their associated user and votes information
EXPLAIN ANALYZE
SELECT p.Id AS PostId,
       p.Title,
       p.CreationDate,
       p.Score,
       p.ViewCount,
       u.DisplayName AS OwnerDisplayName,
       v.VoteTypeId,
       COUNT(v.Id) AS VoteCount
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN Votes v ON p.Id = v.PostId
WHERE p.CreationDate > NOW() - INTERVAL '1 YEAR'
GROUP BY p.Id, u.DisplayName, v.VoteTypeId
ORDER BY p.CreationDate DESC
LIMIT 100;
