WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostScoreAnalysis AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Score,
        P.ViewCount,
        DENSE_RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS ScoreRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= '2023-01-01' 
        AND P.Score IS NOT NULL
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(PA.Score), 0) AS TotalPostScore,
        COALESCE(SUM(PA.ViewCount), 0) AS TotalPostViews,
        COUNT(DISTINCT P.Id) AS PostCount,
        AVG(PA.Score) AS AvgPostScore,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        RANK() OVER (ORDER BY COALESCE(SUM(PA.Score), 0) DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        PostScoreAnalysis PA ON U.Id = PA.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    UPS.UserId,
    UPS.DisplayName,
    UPS.TotalPostScore,
    UPS.TotalPostViews,
    UPS.PostCount,
    UPS.AvgPostScore,
    UPS.TotalBadges,
    UBC.GoldBadges,
    UBC.SilverBadges,
    UBC.BronzeBadges,
    UPS.UserRank,
    CASE 
        WHEN UPS.AvgPostScore > 10 THEN 'High Achiever'
        WHEN UPS.AvgPostScore BETWEEN 5 AND 10 THEN 'Intermediate'
        ELSE 'Novice'
    END AS UserLevel
FROM 
    UserPostStats UPS
LEFT JOIN 
    UserBadgeCounts UBC ON UPS.UserId = UBC.UserId
WHERE 
    UPS.PostCount > 5 
ORDER BY 
    UPS.TotalPostScore DESC, 
    UPS.UserRank ASC
LIMIT 50;
