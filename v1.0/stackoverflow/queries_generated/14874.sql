-- Performance benchmarking query to analyze posts performance by user engagement
SELECT 
    U.DisplayName AS UserName,
    COUNT(DISTINCT P.Id) AS TotalPosts,
    SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    SUM(P.ViewCount) AS TotalViews,
    SUM(P.Score) AS TotalScore,
    AVG(P.Score) AS AverageScore,
    AVG(P.ViewCount) AS AverageViews,
    COUNT(C.Id) AS TotalComments
FROM 
    Users U
JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
WHERE 
    P.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY 
    U.Id
ORDER BY 
    TotalScore DESC, TotalPosts DESC;
