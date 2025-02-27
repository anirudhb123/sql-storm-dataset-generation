-- Performance Benchmarking SQL Query

-- This query will return metrics about Posts and their associated User activity,
-- including the number of Posts, average Score, and average ViewCount.

SELECT 
    U.DisplayName AS UserName,
    COUNT(P.Id) AS TotalPosts,
    AVG(P.Score) AS AverageScore,
    AVG(P.ViewCount) AS AverageViews,
    SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    SUM(CASE WHEN P.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TotalTagWikis,
    SUM(COALESCE(C.CommentCount, 0)) AS TotalComments
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
GROUP BY 
    U.DisplayName
ORDER BY 
    TotalPosts DESC;
