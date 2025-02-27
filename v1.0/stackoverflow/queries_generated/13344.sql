-- Performance benchmarking query example for the StackOverflow schema

-- Benchmarking the following metrics:
-- 1. Count of Posts per Post Type
-- 2. Average Score of Posts
-- 3. Number of Comments on Posts
-- 4. Users with the highest reputation

WITH PostMetrics AS (
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore,
        SUM(COALESCE(c.CommentCount, 0)) AS TotalComments
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    GROUP BY 
        pt.Name
),
UserReputation AS (
    SELECT 
        u.DisplayName,
        u.Reputation
    FROM 
        Users u
    ORDER BY 
        u.Reputation DESC
    LIMIT 10
)

SELECT 
    pm.PostTypeName,
    pm.PostCount,
    pm.AverageScore,
    pm.TotalComments,
    ur.DisplayName AS TopUser,
    ur.Reputation
FROM 
    PostMetrics pm
CROSS JOIN 
    UserReputation ur
ORDER BY 
    pm.PostCount DESC;
