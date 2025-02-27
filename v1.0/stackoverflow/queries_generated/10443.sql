-- Performance benchmarking query for Stack Overflow schema

-- This query retrieves users with their total reputation, number of posts, and average score of their accepted answers
WITH UserPostStats AS (
    SELECT 
        u.Id as UserId,
        u.Reputation,
        COUNT(p.Id) AS TotalPosts,
        AVG(CASE WHEN p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL THEN p.Score END) AS AvgAcceptedAnswerScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
)

-- Fetch user statistics and order by total reputation and total posts
SELECT
    UserId,
    Reputation,
    TotalPosts,
    COALESCE(AvgAcceptedAnswerScore, 0) AS AvgAcceptedAnswerScore
FROM 
    UserPostStats
ORDER BY 
    Reputation DESC, TotalPosts DESC
LIMIT 100; -- limiting to top 100 users for performance
