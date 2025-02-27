SELECT 
    U.DisplayName AS UserDisplayName,
    COUNT(DISTINCT P.Id) AS TotalPosts,
    SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    AVG(P.Score) AS AverageScore,
    SUM(COALESCE(BA.Class = 1, 0)) AS GoldBadges,
    SUM(COALESCE(BA.Class = 2, 0)) AS SilverBadges,
    SUM(COALESCE(BA.Class = 3, 0)) AS BronzeBadges,
    MAX(P.CreationDate) AS LastPostDate,
    COUNT(DISTINCT V.UserId) AS UniqueVoters
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Badges BA ON U.Id = BA.UserId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    U.Reputation > 100
    AND BA.Date >= NOW() - INTERVAL '1 YEAR'
GROUP BY 
    U.DisplayName
ORDER BY 
    TotalPosts DESC, AverageScore DESC
LIMIT 10;
