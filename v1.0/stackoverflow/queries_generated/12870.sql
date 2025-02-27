-- Performance benchmarking query for the StackOverflow schema

-- This query retrieves the count of posts, average score, and view count per post type,
-- as well as the total number of users and the average reputation of those users.

WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore,
        AVG(p.ViewCount) AS AverageViewCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UserStats AS (
    SELECT 
        COUNT(u.Id) AS UserCount,
        AVG(u.Reputation) AS AverageReputation
    FROM 
        Users u
)

SELECT 
    ps.PostType,
    ps.PostCount,
    ps.AverageScore,
    ps.AverageViewCount,
    us.UserCount,
    us.AverageReputation
FROM 
    PostStats ps,
    UserStats us
ORDER BY 
    ps.PostType;
