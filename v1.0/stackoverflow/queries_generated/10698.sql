-- Performance Benchmarking Query
-- This query retrieves the average score, number of answers, and total views for questions by users with at least one badge.

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    AVG(P.Score) AS AvgScore,
    SUM(P.AnswerCount) AS TotalAnswers,
    SUM(P.ViewCount) AS TotalViews
FROM 
    Users U
JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Badges B ON U.Id = B.UserId
WHERE 
    P.PostTypeId = 1 -- Only questions
    AND B.Id IS NOT NULL -- Users that have at least one badge
GROUP BY 
    U.Id, U.DisplayName
ORDER BY 
    TotalViews DESC
LIMIT 10;
