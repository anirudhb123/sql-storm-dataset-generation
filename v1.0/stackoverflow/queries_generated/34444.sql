WITH RECURSIVE UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostScoreOverview AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Score,
        P.AnswerCount,
        P.ViewCount,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS RankByScore
    FROM 
        Posts P
    WHERE 
        P.Score > 0
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS ClosureCount,
        ARRAY_AGG(PH.CreationDate ORDER BY PH.CreationDate) AS ClosureDates
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        PH.PostId
),
UserPosts as (
    SELECT 
        U.Id AS UserId,
        COUNT(P.Id) AS TotalPosts,
        AVG(P.ViewCount) AS AvgViewCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
)

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    U.BadgeCount,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    COALESCE(UP.TotalPosts, 0) AS TotalPosts,
    COALESCE(UP.AvgViewCount, 0) AS AvgViewCount,
    P.PostId,
    P.Score,
    P.AnswerCount,
    P.ViewCount,
    P.CreationDate,
    COALESCE(CP.ClosureCount, 0) AS ClosureCount,
    COALESCE(CP.ClosureDates, '{}') AS ClosureDates
FROM 
    UserBadgeCounts U 
LEFT JOIN 
    UserPosts UP ON U.UserId = UP.UserId
LEFT JOIN 
    PostScoreOverview P ON U.UserId = P.OwnerUserId AND P.RankByScore <= 3 -- Top 3 scored posts
LEFT JOIN 
    ClosedPosts CP ON P.PostId = CP.PostId
WHERE 
    U.BadgeCount > 0 
ORDER BY 
    U.Reputation DESC, 
    P.Score DESC;
