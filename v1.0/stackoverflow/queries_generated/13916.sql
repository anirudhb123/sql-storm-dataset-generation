-- Performance Benchmarking Query
-- This query retrieves statistics related to posts, users, and their activities over time.
-- It aggregates the number of posts and comments per user, as well as the average score of posts.
-- The data is grouped by user, providing a comprehensive overview of user contributions.

WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        AVG(p.Score) AS AvgPostScore,
        SUM(b.Class) AS TotalBadges,
        SUM(coalesce(p.ViewCount, 0)) AS TotalViews
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    CommentCount,
    COALESCE(AvgPostScore, 0) AS AvgPostScore,
    TotalBadges,
    TotalViews
FROM UserStats
ORDER BY PostCount DESC, AvgPostScore DESC;
