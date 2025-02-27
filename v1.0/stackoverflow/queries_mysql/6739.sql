
SELECT 
    U.DisplayName AS UserDisplayName,
    COUNT(DISTINCT P.Id) AS TotalPosts,
    SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    AVG(P.Score) AS AverageScore,
    COUNT(C.Id) AS TotalComments,
    SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
    SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
    SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
    DATE(P.CreationDate) AS PostDate
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Badges B ON U.Id = B.UserId
WHERE 
    U.Reputation >= 1000 
    AND P.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
GROUP BY 
    U.DisplayName, DATE(P.CreationDate)
ORDER BY 
    TotalPosts DESC, AverageScore DESC
LIMIT 50;
