-- Performance Benchmarking SQL Query

-- This query retrieves the count of posts, distinct users, and average reputation of users who created posts,
-- along with a breakdown of post types and their average scores, in order to evaluate the performance of database operations.

WITH PostMetrics AS (
    SELECT 
        Posts.PostTypeId,
        COUNT(Posts.Id) AS PostCount,
        AVG(Posts.Score) AS AverageScore,
        COUNT(DISTINCT Posts.OwnerUserId) AS UniqueUsers
    FROM 
        Posts
    GROUP BY 
        Posts.PostTypeId
),
UserMetrics AS (
    SELECT 
        AVG(Users.Reputation) AS AverageReputation,
        COUNT(Users.Id) AS TotalUsers
    FROM 
        Users
)

SELECT 
    P.PostTypeId,
    P.PostCount,
    P.AverageScore,
    U.AverageReputation,
    U.TotalUsers
FROM 
    PostMetrics P,
    UserMetrics U
ORDER BY 
    P.PostTypeId;
