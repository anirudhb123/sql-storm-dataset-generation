WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
), TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalBadges, 
        GoldBadges, 
        SilverBadges, 
        BronzeBadges,
        RANK() OVER (ORDER BY TotalBadges DESC) AS BadgeRank
    FROM 
        UserBadges
), ActivePosts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    U.DisplayName,
    COALESCE(AP.PostCount, 0) AS RecentPostCount,
    COALESCE(AP.TotalScore, 0) AS RecentTotalScore,
    COALESCE(AP.TotalViews, 0) AS RecentTotalViews,
    T.TotalBadges,
    T.GoldBadges,
    T.SilverBadges,
    T.BronzeBadges
FROM 
    TopUsers T
LEFT JOIN 
    ActivePosts AP ON T.UserId = AP.OwnerUserId
WHERE 
    T.BadgeRank <= 10
ORDER BY 
    T.BadgeRank;
