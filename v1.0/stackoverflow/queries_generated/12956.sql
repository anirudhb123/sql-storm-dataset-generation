-- Performance Benchmarking Query
-- This query retrieves the count of posts, average view counts, and total votes grouped by post types,
-- along with user statistics such as average reputation and total number of badges per user.

WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        AVG(p.ViewCount) AS AvgViewCount,
        SUM(v.Id IS NOT NULL) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        pt.Name
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        AVG(u.Reputation) AS AvgReputation,
        COUNT(b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)

SELECT 
    ps.PostType,
    ps.PostCount,
    ps.AvgViewCount,
    ps.TotalVotes,
    us.AvgReputation,
    us.TotalBadges
FROM 
    PostStats ps
JOIN 
    UserStats us ON us.UserId IN (SELECT OwnerUserId FROM Posts WHERE OwnerUserId IS NOT NULL)
ORDER BY 
    ps.PostType;
