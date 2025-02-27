
SELECT 
    U.DisplayName AS UserDisplayName,
    U.Reputation,
    COUNT(P.Id) AS TotalPosts,
    SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
    SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
    SUM(P.ViewCount) AS TotalViews,
    SUM(P.Score) AS TotalScore,
    AVG(COALESCE(CHAR_LENGTH(P.Body), 0)) AS AveragePostLength,
    COUNT(C.Id) AS TotalComments,
    COUNT(B.Id) AS TotalBadges
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Badges B ON U.Id = B.UserId
WHERE 
    U.CreationDate < NOW() - INTERVAL 1 YEAR  
GROUP BY 
    U.DisplayName, U.Reputation
ORDER BY 
    TotalPosts DESC
LIMIT 100;
