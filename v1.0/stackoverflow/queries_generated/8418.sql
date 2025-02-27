WITH UserBadgeCounts AS (
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
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserPerformance AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate AS AccountAge,
        COALESCE(UBC.BadgeCount, 0) AS BadgeCount,
        COALESCE(UBC.GoldBadges, 0) AS GoldBadges,
        COALESCE(UBC.SilverBadges, 0) AS SilverBadges,
        COALESCE(UBC.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(PS.PostCount, 0) AS PostCount,
        COALESCE(PS.TotalScore, 0) AS TotalScore,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        COALESCE(PS.AverageScore, 0) AS AverageScore,
        PS.LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCounts UBC ON U.Id = UBC.UserId
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
    ORDER BY 
        U.Reputation DESC, PS.TotalScore DESC, U.DisplayName
)
SELECT 
    UserId, 
    DisplayName, 
    Reputation, 
    AccountAge, 
    BadgeCount, 
    GoldBadges, 
    SilverBadges, 
    BronzeBadges, 
    PostCount, 
    TotalScore, 
    TotalViews, 
    AverageScore, 
    LastPostDate
FROM 
    UserPerformance
WHERE 
    PostCount > 5
    AND Reputation > 50
    AND AccountAge < INTERVAL '3 years'
LIMIT 100;
