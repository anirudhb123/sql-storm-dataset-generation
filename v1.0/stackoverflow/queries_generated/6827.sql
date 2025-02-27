WITH UserStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN P.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPostsCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
), PopularPostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        U.DisplayName AS OwnerName
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.ViewCount > 100
), BadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS TotalBadges
    FROM 
        Badges
    GROUP BY 
        UserId
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.TotalPosts,
    US.QuestionsCount,
    US.AnswersCount,
    US.PopularPostsCount,
    COALESCE(BC.TotalBadges, 0) AS TotalBadges,
    PPP.PostId,
    PPP.Title,
    PPP.ViewCount,
    PPP.OwnerName
FROM 
    UserStats US
LEFT JOIN 
    BadgeCounts BC ON US.UserId = BC.UserId
LEFT JOIN 
    PopularPostDetails PPP ON US.UserId = PPP.OwnerName
ORDER BY 
    US.Reputation DESC, 
    US.TotalPosts DESC
LIMIT 50;
