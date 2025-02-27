-- Performance Benchmarking Query for StackOverflow Schema

-- This query retrieves user statistics along with their post and badge details
-- It benchmarks the performance of joins and aggregations in the schema.

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS PostCount,
    SUM(b.Class) AS TotalBadgeClass,
    AVG(v.CreationDate) AS AverageVoteDate,
    MAX(p.CreationDate) AS MostRecentPostDate
FROM Users u
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN Badges b ON u.Id = b.UserId
LEFT JOIN Votes v ON p.Id = v.PostId
GROUP BY u.Id, u.DisplayName, u.Reputation
ORDER BY PostCount DESC, TotalBadgeClass DESC;
