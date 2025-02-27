
WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        @rownum := @rownum + 1 AS Rank
    FROM 
        Users U, (SELECT @rownum := 0) r
    ORDER BY 
        U.Reputation DESC
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
UserRecentPosts AS (
    SELECT 
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        @recentpostnum := IF(@currentuser = P.OwnerUserId, @recentpostnum + 1, 1) AS RecentPostRank,
        @currentuser := P.OwnerUserId
    FROM 
        Posts P, (SELECT @recentpostnum := 0, @currentuser := '') AS vars
    ORDER BY 
        P.OwnerUserId, P.CreationDate DESC
)

SELECT 
    RU.UserId,
    RU.DisplayName,
    RU.Reputation,
    UB.BadgeCount,
    URP.Title AS RecentPostTitle,
    URP.CreationDate AS RecentPostDate
FROM 
    RankedUsers RU
LEFT JOIN 
    UserBadges UB ON RU.UserId = UB.UserId
LEFT JOIN 
    UserRecentPosts URP ON RU.UserId = URP.OwnerUserId AND URP.RecentPostRank = 1
WHERE 
    RU.Rank <= 10;
