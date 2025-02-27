-- Performance Benchmarking Query

WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS VerifiedPosts,
        AVG(p.Score) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        Questions,
        Answers,
        VerifiedPosts,
        AvgScore,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS Rank
    FROM 
        UserPostStats
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    Questions,
    Answers,
    VerifiedPosts,
    AvgScore
FROM 
    TopUsers
WHERE 
    Rank <= 10
ORDER BY 
    TotalPosts DESC;

-- This query retrieves the top 10 users based on the total number of posts,
-- along with a breakdown of their posts, including the number of questions and answers, 
-- the number of verified posts, and their average score.
