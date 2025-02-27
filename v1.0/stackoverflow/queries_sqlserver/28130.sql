
SELECT 
    U.DisplayName AS UserName,
    COUNT(DISTINCT P.Id) AS TotalPosts,
    SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    AVG(P.Score) AS AvgScore,
    STRING_AGG(DISTINCT T.TagName, ', ') AS Tags,
    SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
    SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
    SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
    MAX(P.CreationDate) AS LastPostDate
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Badges B ON U.Id = B.UserId
OUTER APPLY (SELECT DISTINCT value AS TagName FROM STRING_SPLIT(P.Tags, '><')) T
WHERE 
    U.Reputation > 100
GROUP BY 
    U.Id, U.DisplayName
ORDER BY 
    TotalPosts DESC, AvgScore DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
