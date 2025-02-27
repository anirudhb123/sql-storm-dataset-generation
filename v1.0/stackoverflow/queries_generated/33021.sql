WITH RECURSIVE UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        1 AS ActivityLevel
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000 AND U.LastAccessDate >= NOW() - INTERVAL '1 year'
    
    UNION ALL
    
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        UA.ActivityLevel + 1
    FROM 
        Users U
    JOIN 
        UserActivity UA ON U.Id = UA.UserId
    WHERE 
        U.Reputation > 500 AND U.CreationDate < NOW() - INTERVAL '5 year'
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN PT.Name = 'Question' THEN 1 END) AS Questions,
        COUNT(CASE WHEN PT.Name = 'Answer' THEN 1 END) AS Answers,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    GROUP BY 
        P.OwnerUserId
),
BadgeCounts AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    U.Id,
    U.DisplayName,
    COALESCE(PS.TotalPosts, 0) AS TotalPosts,
    COALESCE(BC.BadgeCount, 0) AS BadgeCount,
    COALESCE(BC.GoldBadges, 0) AS GoldBadges,
    COALESCE(BC.SilverBadges, 0) AS SilverBadges,
    COALESCE(BC.BronzeBadges, 0) AS BronzeBadges,
    UA.ActivityLevel AS UserActivityLevel
FROM 
    Users U
LEFT JOIN 
    PostStatistics PS ON U.Id = PS.OwnerUserId
LEFT JOIN 
    BadgeCounts BC ON U.Id = BC.UserId
LEFT JOIN 
    UserActivity UA ON U.Id = UA.UserId
WHERE 
    U.Reputation > 1000
ORDER BY 
    U.DisplayName,
    COALESCE(PS.TotalPosts, 0) DESC,
    COALESCE(BC.BadgeCount, 0) DESC
LIMIT 100;

-- Compare user statistics against posts with comments longer than 200 characters
WITH LongCommentStats AS (
    SELECT 
        C.UserId,
        COUNT(C.Id) AS LongCommentCount,
        SUM(LENGTH(C.Text)) AS TotalCommentLength
    FROM 
        Comments C
    WHERE 
        LENGTH(C.Text) > 200
    GROUP BY 
        C.UserId
)

SELECT 
    U.DisplayName,
    COALESCE(LCS.LongCommentCount, 0) AS LongCommentCount,
    COALESCE(LCS.TotalCommentLength, 0) AS TotalCommentLength
FROM 
    Users U
LEFT JOIN 
    LongCommentStats LCS ON U.Id = LCS.UserId
WHERE 
    U.Reputation > 100 

UNION ALL

SELECT 
    'Total' AS DisplayName,
    SUM(COALESCE(LongCommentCount, 0)) AS LongCommentCount,
    SUM(COALESCE(TotalCommentLength, 0)) AS TotalCommentLength
FROM 
    LongCommentStats;

