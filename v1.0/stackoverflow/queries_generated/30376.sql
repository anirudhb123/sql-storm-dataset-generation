WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.OwnerUserId, 
        p.CreationDate, 
        1 AS Level
    FROM Posts p 
    WHERE p.PostTypeId = 1  -- Start with questions

    UNION ALL

    SELECT 
        p2.Id AS PostId, 
        p2.Title, 
        p2.OwnerUserId, 
        p2.CreationDate, 
        rp.Level + 1
    FROM Posts p2
    JOIN RecursivePostCTE rp ON p2.ParentId = rp.PostId
)
SELECT 
    u.DisplayName,
    COALESCE(b.BadgesCount, 0) AS BadgeCount,
    COUNT(pp.PostId) AS TotalPosts,
    SUM(CASE WHEN pp.Level = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN pp.Level > 1 THEN 1 ELSE 0 END) AS TotalAnswers,
    MAX(pp.CreationDate) AS LastPostDate
FROM Users u
LEFT JOIN (
    SELECT 
        UserId, 
        COUNT(*) AS BadgesCount
    FROM Badges
    GROUP BY UserId
) b ON u.Id = b.UserId
LEFT JOIN RecursivePostCTE pp ON u.Id = pp.OwnerUserId
GROUP BY u.DisplayName, b.BadgesCount
HAVING COUNT(pp.PostId) > 10 -- Users with more than 10 posts
ORDER BY BadgeCount DESC, TotalPosts DESC;

-- Explain Plan for analyzing performance:
EXPLAIN ANALYZE 
WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.OwnerUserId, 
        p.CreationDate, 
        1 AS Level
    FROM Posts p 
    WHERE p.PostTypeId = 1  -- Start with questions

    UNION ALL

    SELECT 
        p2.Id AS PostId, 
        p2.Title, 
        p2.OwnerUserId, 
        p2.CreationDate, 
        rp.Level + 1
    FROM Posts p2
    JOIN RecursivePostCTE rp ON p2.ParentId = rp.PostId
)
SELECT 
    u.DisplayName,
    COALESCE(b.BadgesCount, 0) AS BadgeCount,
    COUNT(pp.PostId) AS TotalPosts,
    SUM(CASE WHEN pp.Level = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN pp.Level > 1 THEN 1 ELSE 0 END) AS TotalAnswers,
    MAX(pp.CreationDate) AS LastPostDate
FROM Users u
LEFT JOIN (
    SELECT 
        UserId, 
        COUNT(*) AS BadgesCount
    FROM Badges
    GROUP BY UserId
) b ON u.Id = b.UserId
LEFT JOIN RecursivePostCTE pp ON u.Id = pp.OwnerUserId
GROUP BY u.DisplayName, b.BadgesCount
HAVING COUNT(pp.PostId) > 10
ORDER BY BadgeCount DESC, TotalPosts DESC;

This SQL query consists of a recursive common table expression (CTE) that retrieves all posts along with their hierarchical relationships. The query then aggregates user metrics based on their posts and collected badges, with outputs filtered for users with more than 10 total posts, displaying them in descending order of badge count and total posts. An explanation plan command is included for performance analysis.
