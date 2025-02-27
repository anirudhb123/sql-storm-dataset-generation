WITH UserBadges AS (
    SELECT 
        UserId,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
RecentPosts AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.OwnerUserId,
        Posts.Title,
        Posts.CreationDate,
        Posts.Score,
        RANK() OVER (PARTITION BY Posts.OwnerUserId ORDER BY Posts.CreationDate DESC) AS PostRank
    FROM 
        Posts
    WHERE 
        Posts.CreationDate >= NOW() - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        COALESCE(UB.GoldBadges, 0) AS GoldBadges,
        COALESCE(UB.SilverBadges, 0) AS SilverBadges,
        COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN 
        RecentPosts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 100
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, UB.GoldBadges, UB.SilverBadges, UB.BronzeBadges
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.GoldBadges,
    TU.SilverBadges,
    TU.BronzeBadges,
    TU.PostCount,
    CASE 
        WHEN TU.PostCount > 10 THEN 'Active' 
        ELSE 'Less Active' 
    END AS ActivityStatus
FROM 
    TopUsers TU
ORDER BY 
    TU.Reputation DESC, TU.PostCount DESC
LIMIT 10;
