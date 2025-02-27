-- Performance benchmarking query for the Stack Overflow schema

-- This query retrieves the total number of posts, users, and votes made in the last year,
-- alongside the average reputation of users who authored these posts 
-- and the count of different post types to assess the distribution of post types.

WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.OwnerUserId,
        u.Reputation AS UserReputation,
        p.CreationDate
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostCounts AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS TotalUsers,
        AVG(UserReputation) AS AverageUserReputation
    FROM 
        RecentPosts
),
PostTypeCounts AS (
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(*) AS PostTypeCount
    FROM 
        RecentPosts rp
    JOIN 
        PostTypes pt ON rp.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)

SELECT 
    pc.TotalPosts,
    pc.TotalUsers,
    pc.AverageUserReputation,
    ptc.PostTypeName,
    ptc.PostTypeCount
FROM 
    PostCounts pc
LEFT JOIN 
    PostTypeCounts ptc ON true  -- this join allows including all post types
ORDER BY 
    ptc.PostTypeName;
