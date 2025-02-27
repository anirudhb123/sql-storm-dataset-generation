WITH UserBadges AS (
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
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        AVG(P.ViewCount) AS AverageViews
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        UB.BadgeCount,
        PS.PostCount,
        PS.TotalScore,
        PS.AverageViews,
        RANK() OVER (ORDER BY PS.TotalScore DESC) AS ScoreRank
    FROM 
        Users U
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
)
SELECT 
    TU.DisplayName,
    TU.BadgeCount,
    TU.PostCount,
    TU.TotalScore,
    TU.AverageViews,
    RANK() OVER (ORDER BY TU.BadgeCount DESC) AS BadgeRank
FROM 
    TopUsers TU
WHERE 
    TU.PostCount > 5
UNION ALL
SELECT 
    'No User' AS DisplayName,
    0 AS BadgeCount,
    COUNT(DISTINCT P.Id) AS PostCount,
    0 AS TotalScore,
    AVG(P.ViewCount) AS AverageViews
FROM 
    Posts P
WHERE 
    P.OwnerUserId IS NULL
GROUP BY 
    P.OwnerUserId
HAVING 
    COUNT(DISTINCT P.Id) > 5
ORDER BY 
    BadgeRank, ScoreRank;
