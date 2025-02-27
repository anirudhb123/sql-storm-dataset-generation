-- Performance Benchmarking Query for Stack Overflow Schema

-- This query benchmarks the time taken to retrieve user statistics along with their most recent posts and comments.
WITH RecentUserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        COUNT(DISTINCT p.Id) AS RecentPostCount,
        COUNT(DISTINCT c.Id) AS RecentCommentCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.CreationDate > NOW() - INTERVAL '30 days' 
    LEFT JOIN 
        Comments c ON u.Id = c.UserId AND c.CreationDate > NOW() - INTERVAL '30 days' 
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate, u.LastAccessDate
)
SELECT 
    *
FROM 
    RecentUserStats
ORDER BY 
    Reputation DESC
LIMIT 100;

