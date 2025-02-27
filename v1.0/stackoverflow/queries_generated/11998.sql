-- Performance Benchmarking Query
-- This query retrieves counts and average scores for posts, along with user information to analyze performance
SELECT 
    U.DisplayName AS UserDisplayName,
    U.Reputation AS UserReputation,
    COUNT(P.Id) AS TotalPosts,
    AVG(P.Score) AS AverageScore,
    SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    SUM(CASE WHEN P.PostTypeId = 3 THEN 1 ELSE 0 END) AS TotalWikis,
    SUM(CASE WHEN P.PostTypeId IN (1, 2) THEN P.ViewCount ELSE 0 END) AS TotalViews
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
WHERE 
    U.Reputation > 0  -- Filter out users with no reputation
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
ORDER BY 
    TotalPosts DESC
LIMIT 100; -- Limit to top 100 users based on post counts
