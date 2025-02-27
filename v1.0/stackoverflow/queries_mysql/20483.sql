
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE 
            WHEN B.Class = 1 THEN 1 
            ELSE 0 
        END) AS GoldBadges,
        SUM(CASE 
            WHEN B.Class = 2 THEN 1 
            ELSE 0 
        END) AS SilverBadges,
        SUM(CASE 
            WHEN B.Class = 3 THEN 1 
            ELSE 0 
        END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(IFNULL(P.Score, 0)) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount,
        MAX(P.CreationDate) AS LatestPostDate
    FROM 
        Posts P
    WHERE 
        P.CreationDate > DATE_SUB('2024-10-01', INTERVAL 1 YEAR)
    GROUP BY 
        P.OwnerUserId
),
UserPosts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        PS.PostCount,
        PS.TotalScore,
        PS.AvgViewCount,
        PS.LatestPostDate,
        UB.BadgeCount,
        UB.GoldBadges,
        UB.SilverBadges,
        UB.BronzeBadges,
        @row_num := IF(U.Id = @prev_id, @row_num + 1, 1) AS ScoreRank,
        @prev_id := U.Id
    FROM 
        Users U
    LEFT JOIN 
        PostStatistics PS ON U.Id = PS.OwnerUserId
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId,
        (SELECT @row_num := 0, @prev_id := NULL) AS vars
    ORDER BY 
        PS.TotalScore DESC NULLS LAST
)
SELECT 
    U.DisplayName,
    COALESCE(UP.PostCount, 0) AS NumberOfPosts,
    COALESCE(UP.TotalScore, 0) AS TotalScore,
    COALESCE(UP.AvgViewCount, 0) AS AverageViewCount,
    COALESCE(UP.BadgeCount, 0) AS TotalBadges,
    COALESCE(UP.GoldBadges, 0) AS GoldBadges,
    COALESCE(UP.SilverBadges, 0) AS SilverBadges,
    COALESCE(UP.BronzeBadges, 0) AS BronzeBadges,
    CASE 
        WHEN UP.ScoreRank IS NULL THEN 'No Posts'
        ELSE CAST(UP.ScoreRank AS CHAR)
    END AS Rank
FROM 
    Users U
LEFT JOIN 
    UserPosts UP ON U.Id = UP.UserId
WHERE 
    U.LastAccessDate > DATE_SUB('2024-10-01', INTERVAL 6 MONTH)
ORDER BY 
    TotalScore DESC, 
    NumberOfPosts DESC, 
    DisplayName;
