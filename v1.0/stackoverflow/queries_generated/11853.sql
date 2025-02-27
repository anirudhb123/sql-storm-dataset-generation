-- Performance Benchmarking Query for StackOverflow Schema
-- This query retrieves users with their total post count, total votes, and average reputation.

WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COALESCE(SUM(v.VoteTypeId IN (2)), 0) AS TotalUpvotes,
        COALESCE(SUM(v.VoteTypeId IN (3)), 0) AS TotalDownvotes,
        AVG(u.Reputation) AS AverageReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalUpvotes,
    TotalDownvotes,
    AverageReputation
FROM 
    UserPostStats
ORDER BY 
    TotalPosts DESC
LIMIT 100; -- Limit to top 100 users by post count
