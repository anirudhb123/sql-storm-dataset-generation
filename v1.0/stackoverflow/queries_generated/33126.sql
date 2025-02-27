WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.OwnerUserId, 
        p.ParentId, 
        0 AS Level 
    FROM Posts p
    WHERE p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.OwnerUserId, 
        p.ParentId, 
        r.Level + 1 
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.PostId
),
AveragePostsPerUser AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(p.Id) AS PostCount, 
        AVG(v.Score) AS AverageScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- Up votes
    GROUP BY u.Id
),
RecentActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT p.Id) AS PostCount, 
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM Users u
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY u.Id, u.DisplayName
)
SELECT
    u.DisplayName, 
    u.Reputation, 
    r.PostId, 
    r.Title, 
    ph.ChildPostsCount,
    a.PostCount AS UserPostCount,
    a.AverageScore,
    ra.CommentCount,
    ra.TotalViews
FROM Users u
INNER JOIN RecursivePostHierarchy r ON u.Id = r.OwnerUserId
LEFT JOIN (
    SELECT 
        ParentId,
        COUNT(*) AS ChildPostsCount
    FROM Posts
    WHERE ParentId IS NOT NULL
    GROUP BY ParentId
) ph ON r.PostId = ph.ParentId
JOIN AveragePostsPerUser a ON u.Id = a.UserId
LEFT JOIN RecentActivity ra ON u.Id = ra.UserId
WHERE r.Level = 0  -- Filter to show only the top-level posts (questions)
ORDER BY u.Reputation DESC, ra.TotalViews DESC, a.PostCount DESC;
