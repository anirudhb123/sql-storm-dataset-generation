-- Performance Benchmarking Query

-- This query retrieves the number of posts per user, the average score of those posts,
-- and the total number of votes each user has received, aggregating data for performance analysis.

WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS TotalPosts,
        COALESCE(AVG(p.Score), 0) AS AveragePostScore,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
)

SELECT 
    ups.UserId,
    ups.TotalPosts,
    ups.AveragePostScore,
    ups.TotalVotes
FROM 
    UserPostStats ups
ORDER BY 
    ups.TotalPosts DESC;  -- Sort by the number of posts in descending order for clearer insights
