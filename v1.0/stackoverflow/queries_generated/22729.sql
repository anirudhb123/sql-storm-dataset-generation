WITH UserBadgeStats AS (
    SELECT 
        U.Id AS UserId,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(DISTINCT B.Id) AS TotalBadges
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
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AvgScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserPerformance AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(BS.GoldBadges, 0) AS GoldBadges,
        COALESCE(BS.SilverBadges, 0) AS SilverBadges,
        COALESCE(BS.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.Questions, 0) AS Questions,
        COALESCE(PS.Answers, 0) AS Answers,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        COALESCE(PS.AvgScore, 0) AS AvgScore,
        COALESCE(PS.LastPostDate, '1900-01-01') AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeStats BS ON U.Id = BS.UserId
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
)
SELECT 
    UP.DisplayName,
    UP.GoldBadges,
    UP.SilverBadges,
    UP.BronzeBadges,
    UP.TotalPosts,
    UP.Questions,
    UP.Answers,
    UP.TotalViews,
    UP.AvgScore,
    CASE
        WHEN UP.LastPostDate = '1900-01-01' THEN 'No Posts Yet'
        ELSE TO_CHAR(UP.LastPostDate, 'YYYY-MM-DD')
    END AS FormattedLastPostDate,
    CASE 
        WHEN UP.TotalViews IS NULL THEN 'No Activity' 
        WHEN UP.TotalViews < 100 THEN 'Low Activity' 
        WHEN UP.TotalViews BETWEEN 100 AND 999 THEN 'Moderate Activity' 
        ELSE 'High Activity' 
    END AS ActivityLevel
FROM 
    UserPerformance UP
ORDER BY 
    UP.TotalPosts DESC, 
    UP.GoldBadges DESC;
