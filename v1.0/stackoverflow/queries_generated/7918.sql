SELECT 
    U.DisplayName AS UserName,
    U.Reputation,
    COUNT(P.Id) AS TotalPosts,
    SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    MAX(P.Score) AS MaxPostScore,
    AVG(P.ViewCount) AS AverageViews,
    COUNT(DISTINCT C.Id) AS TotalComments,
    STRING_AGG(DISTINCT T.TagName, ', ') AS AssociatedTags,
    COUNT(DISTINCT B.Id) AS TotalBadges
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    PostLinks PL ON P.Id = PL.PostId
LEFT JOIN 
    Tags T ON P.Tags LIKE '%' || T.TagName || '%'
LEFT JOIN 
    Badges B ON U.Id = B.UserId
WHERE 
    U.Reputation > 1000
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
HAVING 
    COUNT(P.Id) > 5
ORDER BY 
    U.Reputation DESC, TotalPosts DESC
LIMIT 50;
