-- Performance Benchmarking Query

-- This query benchmarks the time taken to fetch user activity data along with their posts and comments 
-- from the Stack Overflow schema, attempting to simulate a real-world scenario by joining multiple tables.

SELECT
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT c.Id) AS TotalComments,
    SUM(COALESCE(p.Score, 0)) AS TotalPostScore,
    SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
    SUM(COALESCE(b.Class, 0)) AS TotalBadges,
    MAX(p.CreationDate) AS LastPostDate
FROM
    Users u
LEFT JOIN
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN
    Comments c ON p.Id = c.PostId
LEFT JOIN
    Badges b ON u.Id = b.UserId
GROUP BY
    u.Id, u.DisplayName, u.Reputation
ORDER BY
    TotalPosts DESC
LIMIT 100; -- Limit to the top 100 users with the most posts for benchmarking purposes
