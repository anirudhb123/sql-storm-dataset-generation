-- Performance Benchmarking Query for StackOverflow Schema

-- This query retrieves the number of posts, average view counts, 
-- total votes, and badge counts for users, providing insight into 
-- post engagement and user recognition across different post types.

WITH PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.ViewCount) AS AvgViewCount,
        SUM(CASE WHEN v.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.PostTypeId
),
UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    pt.Name AS PostType,
    ps.TotalPosts,
    ps.AvgViewCount,
    ps.TotalVotes,
    ub.TotalBadges
FROM 
    PostStats ps
JOIN 
    PostTypes pt ON ps.PostTypeId = pt.Id
LEFT JOIN 
    UserBadgeCounts ub ON ub.UserId = p.OwnerUserId
ORDER BY 
    ps.TotalPosts DESC;
