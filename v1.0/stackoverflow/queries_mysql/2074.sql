
WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN B.Class = 1 THEN B.Id END) AS GoldBadgeCount,
        COUNT(CASE WHEN B.Class = 2 THEN B.Id END) AS SilverBadgeCount,
        COUNT(CASE WHEN B.Class = 3 THEN B.Id END) AS BronzeBadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(IFNULL(P.Score, 0)) AS TotalScore,
        AVG(IFNULL(P.ViewCount, 0)) AS AverageViews
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= '2023-10-01 12:34:56'
    GROUP BY 
        P.OwnerUserId
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        IFNULL(UBC.GoldBadgeCount, 0) AS GoldBadges,
        IFNULL(UBC.SilverBadgeCount, 0) AS SilverBadges,
        IFNULL(UBC.BronzeBadgeCount, 0) AS BronzeBadges,
        PS.TotalPosts,
        PS.TotalScore,
        PS.AverageViews
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCounts UBC ON U.Id = UBC.UserId
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
    WHERE 
        U.Reputation > 1000
)
SELECT 
    T.DisplayName,
    T.Reputation,
    T.GoldBadges,
    T.SilverBadges,
    T.BronzeBadges,
    T.TotalPosts,
    T.TotalScore,
    T.AverageViews,
    CASE 
        WHEN T.TotalScore >= 100 THEN 'High Scorer'
        WHEN T.TotalScore BETWEEN 50 AND 99 THEN 'Moderate Scorer'
        ELSE 'Low Scorer'
    END AS ScoreCategory
FROM 
    TopUsers T
WHERE 
    T.TotalPosts > (SELECT AVG(TotalPosts) FROM TopUsers)
ORDER BY 
    T.Reputation DESC
LIMIT 10;
