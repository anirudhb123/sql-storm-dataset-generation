-- Performance benchmarking query for the Stack Overflow schema

-- This query retrieves the count of Posts, Votes, and Users grouped by PostTypes
-- It includes some aggregate functions to assess performance on data retrieval

WITH PostCounts AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        COUNT(DISTINCT v.UserId) AS TotalVotes,
        COUNT(DISTINCT u.Id) AS TotalUsers
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        pt.Name
)

SELECT 
    PostType,
    TotalPosts,
    TotalVotes,
    TotalUsers,
    TotalVotes::FLOAT / NULLIF(TotalPosts, 0) AS VotesPerPost,
    TotalUsers::FLOAT / NULLIF(TotalPosts, 0) AS UsersPerPost
FROM 
    PostCounts
ORDER BY 
    TotalPosts DESC;
