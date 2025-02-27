WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(P.Score) AS AvgScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        PU.TotalPosts,
        PU.Questions,
        PU.Answers,
        PU.AvgScore,
        PU.TotalViews
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCounts UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostStats PU ON U.Id = PU.OwnerUserId
    WHERE 
        U.Reputation > 1000
)
SELECT 
    T.DisplayName,
    T.TotalPosts,
    T.Questions,
    T.Answers,
    T.BadgeCount,
    T.AvgScore,
    T.TotalViews
FROM 
    TopUsers T
ORDER BY 
    T.BadgeCount DESC, T.TotalPosts DESC
LIMIT 10;

WITH RecentPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COALESCE((SELECT COUNT(C.Id) FROM Comments C WHERE C.PostId = P.Id), 0) AS CommentCount
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days'
),
CloseReasons AS (
    SELECT 
        PH.PostId,
        CT.Name AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CT ON PH.Comment::int = CT.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) 
)
SELECT 
    RP.Title,
    RP.CreationDate,
    RP.ViewCount,
    RP.CommentCount,
    CR.CloseReason
FROM 
    RecentPosts RP
LEFT JOIN 
    CloseReasons CR ON RP.Id = CR.PostId
ORDER BY 
    RP.ViewCount DESC, RP.CreationDate ASC
LIMIT 5;
