WITH RECURSIVE UserBadgeCounts AS (
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
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserPerformance AS (
    SELECT 
        U.Id AS UserId,
        COALESCE(US.TotalPosts, 0) AS TotalPosts,
        COALESCE(US.Questions, 0) AS Questions,
        COALESCE(US.Answers, 0) AS Answers,
        COALESCE(US.TotalViews, 0) AS TotalViews,
        COALESCE(US.TotalScore, 0) AS TotalScore,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(UB.GoldBadges, 0) AS GoldBadges,
        COALESCE(UB.SilverBadges, 0) AS SilverBadges,
        COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
        CASE 
            WHEN COALESCE(UB.BadgeCount, 0) > 5 THEN 'High Achiever'
            WHEN COALESCE(UB.BadgeCount, 0) > 0 THEN 'Active Contributor'
            ELSE 'New User'
        END AS UserCategory
    FROM 
        Users U
    LEFT JOIN PostStats US ON U.Id = US.OwnerUserId
    LEFT JOIN UserBadgeCounts UB ON U.Id = UB.UserId
)
SELECT 
    U.UserId,
    U.TotalPosts,
    U.Questions,
    U.Answers,
    U.TotalViews,
    U.TotalScore,
    U.BadgeCount,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    U.UserCategory,
    (SELECT STRING_AGG(DISTINCT T.TagName, ', ') 
     FROM Posts P 
     JOIN STRING_TO_ARRAY(P.Tags, '><') AS T(TagName) ON P.OwnerUserId = U.UserId 
     WHERE P.PostTypeId = 1) AS FavoriteTags
FROM 
    UserPerformance U
ORDER BY 
    U.TotalScore DESC;
