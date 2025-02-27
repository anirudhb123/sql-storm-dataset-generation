WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RecentPosts AS (
    SELECT 
        P.OwnerUserId,
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days'
),
TopPosts AS (
    SELECT 
        RP.OwnerUserId,
        RP.PostId,
        RP.Title,
        RP.ViewCount,
        RANK() OVER (PARTITION BY RP.OwnerUserId ORDER BY RP.ViewCount DESC) AS RankByViews
    FROM 
        RecentPosts RP
)
SELECT 
    U.DisplayName,
    U.Reputation,
    UR.BadgeCount,
    UR.GoldBadges,
    UR.SilverBadges,
    UR.BronzeBadges,
    TP.Title,
    TP.ViewCount
FROM 
    UserReputation UR
LEFT JOIN 
    TopPosts TP ON UR.UserId = TP.OwnerUserId AND TP.RankByViews = 1
INNER JOIN 
    Users U ON U.Id = UR.UserId
WHERE 
    UR.Reputation > (
        SELECT AVG(Reputation) FROM Users
    )
    OR TP.ViewCount IS NOT NULL
ORDER BY 
    U.Reputation DESC,
    TP.ViewCount DESC NULLS LAST
LIMIT 100;

WITH RECURSIVE PostHierarchy AS (
    SELECT 
        P.Id, 
        P.Title, 
        P.ParentId, 
        0 AS Level 
    FROM 
        Posts P 
    WHERE 
        P.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        P.Id, 
        P.Title, 
        P.ParentId, 
        PH.Level + 1 
    FROM 
        Posts P 
    INNER JOIN 
        PostHierarchy PH ON P.ParentId = PH.Id
)
SELECT 
    P.Id,
    P.Title,
    PH.Level,
    COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
    COUNT(V.Id) AS VoteCount
FROM 
    PostHierarchy PH
LEFT JOIN 
    Posts P ON PH.Id = P.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
GROUP BY 
    P.Id, P.Title, PH.Level;
