-- Performance benchmarking query to analyze user activity and post engagement

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COUNT(DISTINCT P.Id) AS TotalPosts,
    COUNT(DISTINCT A.Id) AS TotalAnswers,
    SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
    SUM(COALESCE(P.Score, 0)) AS TotalScore,
    COUNT(DISTINCT C.Id) AS TotalComments,
    COUNT(DISTINCT B.Id) AS TotalBadges,
    AVG(P.ViewCount) AS AvgViewsPerPost
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Posts A ON U.Id = A.OwnerUserId AND A.PostTypeId = 2 -- Answers
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Badges B ON U.Id = B.UserId
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
ORDER BY 
    TotalPosts DESC, U.Reputation DESC;
