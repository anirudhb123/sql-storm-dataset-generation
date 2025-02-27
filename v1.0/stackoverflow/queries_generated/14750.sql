-- Performance Benchmarking Query

-- This query retrieves the count of posts along with their respective types and the average score
-- across all post types, along with user reputation to evaluate performance on posting behavior

WITH PostStats AS (
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation
    FROM 
        Users u
)
SELECT 
    ps.PostTypeName,
    ps.PostCount,
    ps.AverageScore,
    us.Reputation
FROM 
    PostStats ps
JOIN 
    UserStats us ON us.UserId = p.OwnerUserId
ORDER BY 
    ps.PostCount DESC;

-- Evaluate the performance of each post type in terms of user contributions and engagement.
