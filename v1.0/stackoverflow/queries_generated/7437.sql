SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COUNT(DISTINCT P.Id) AS TotalPosts,
    SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS TotalPositivePosts,
    AVG(P.Score) AS AverageScore,
    AVG(DATEDIFF(SECOND, P.CreationDate, P.LastActivityDate)) AS AvgActiveDuration,
    JSON_AGG(DISTINCT T.TagName) AS Tags,
    (SELECT COUNT(*) FROM Badges B WHERE B.UserId = U.Id AND B.Class = 1) AS GoldBadges,
    (SELECT COUNT(*) FROM Badges B WHERE B.UserId = U.Id AND B.Class = 2) AS SilverBadges,
    (SELECT COUNT(*) FROM Badges B WHERE B.UserId = U.Id AND B.Class = 3) AS BronzeBadges
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Tags T ON P.Tags LIKE CONCAT('%', T.TagName, '%')
WHERE 
    U.Reputation > 1000
GROUP BY 
    U.Id, U.DisplayName
HAVING 
    COUNT(DISTINCT P.Id) > 5
ORDER BY 
    TotalPosts DESC, AverageScore DESC
LIMIT 10;
