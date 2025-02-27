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
LEFT JOIN 
    LATERAL (SELECT DISTINCT UNNEST(STRING_TO_ARRAY(P.Tags, '><')) AS TagName) T ON TRUE
WHERE 
    U.Reputation > 100
GROUP BY 
    U.Id
ORDER BY 
    TotalPosts DESC, AvgScore DESC
LIMIT 10;
This SQL query retrieves and benchmarks users with a reputation greater than 100, compiling statistics on their posts, badge awards, and associated tags. It calculates the total number of posts, distinguishing between questions and answers, while also summing up badges of varying classes, and capturing the last post date for each user. The results are ordered by total posts and average score, showing the top 10 users based on activity.
