
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
        @row_number := IF(@prev_owner_user_id = P.OwnerUserId, @row_number + 1, 1) AS RecentRank,
        @prev_owner_user_id := P.OwnerUserId
    FROM 
        Posts P, (SELECT @row_number := 0, @prev_owner_user_id := NULL) AS init
    WHERE 
        P.CreationDate >= NOW() - INTERVAL 30 DAY
    ORDER BY 
        P.OwnerUserId, P.CreationDate DESC
),
TopPosts AS (
    SELECT 
        RP.OwnerUserId,
        RP.PostId,
        RP.Title,
        RP.ViewCount,
        @rank := IF(@prev_owner_user_id_2 = RP.OwnerUserId, @rank + 1, 1) AS RankByViews,
        @prev_owner_user_id_2 := RP.OwnerUserId
    FROM 
        RecentPosts RP, (SELECT @rank := 0, @prev_owner_user_id_2 := NULL) AS init
    ORDER BY 
        RP.OwnerUserId, RP.ViewCount DESC
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
    TP.ViewCount DESC
LIMIT 100;
