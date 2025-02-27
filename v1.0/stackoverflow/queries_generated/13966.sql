-- Performance benchmarking query for Stack Overflow schema

-- This query retrieves the total number of posts, users, comments and votes
-- It provides insights into the overall activity and size of the database
WITH Metrics AS (
    SELECT
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT u.Id) AS TotalUsers,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT v.Id) AS TotalVotes
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
)
SELECT
    TotalPosts,
    TotalUsers,
    TotalComments,
    TotalVotes,
    (SELECT COUNT(*) FROM PostHistory) AS TotalPostHistoryRecords,
    (SELECT COUNT(*) FROM Badges) AS TotalBadges,
    (SELECT COUNT(*) FROM Tags) AS TotalTags,
    (SELECT COUNT(*) FROM PostLinks) AS TotalPostLinks
FROM Metrics;
