-- Performance Benchmarking Query for StackOverflow Schema

-- Objective: Retrieve the number of posts, average score, and user reputation 
-- for posts created in the last year, grouped by post type and ordered by the number of posts.

WITH PostStats AS (
    SELECT 
        PT.Name AS PostType,
        COUNT(P.Id) AS PostCount,
        AVG(P.Score) AS AverageScore,
        AVG(U.Reputation) AS AverageUserReputation
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        PT.Name
)

SELECT 
    PostType,
    PostCount,
    AverageScore,
    AverageUserReputation
FROM 
    PostStats
ORDER BY 
    PostCount DESC;
