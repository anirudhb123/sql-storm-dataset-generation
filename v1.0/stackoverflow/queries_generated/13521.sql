-- Performance Benchmarking SQL Query

-- This query will retrieve user statistics and their post engagement metrics, 
-- which can be useful for performance benchmarking

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COUNT(DISTINCT P.Id) AS TotalPosts,
    COUNT(DISTINCT A.Id) AS TotalAnswers,
    SUM(COALESCE(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END, 0)) AS TotalQuestions,
    SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
    SUM(COALESCE(P.Score, 0)) AS TotalScore,
    COUNT(DISTINCT C.Id) AS TotalComments,
    COUNT(DISTINCT B.Id) AS TotalBadges
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Posts A ON P.AcceptedAnswerId = A.Id
LEFT JOIN 
    Comments C ON C.UserId = U.Id
LEFT JOIN 
    Badges B ON B.UserId = U.Id
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
ORDER BY 
    U.Reputation DESC;
