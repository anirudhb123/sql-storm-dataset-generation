WITH RECURSIVE PopularTags AS (
    SELECT 
        T.TagName,
        SUM(P.ViewCount) AS TotalViews,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM 
        Tags T 
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
    HAVING 
        SUM(P.ViewCount) > 1000 
), UserBadges AS (
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
), UserPosts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(P.AnswerCount) AS TotalAnswers,
        SUM(P.CommentCount) AS TotalComments,
        AVG(P.Score) AS AverageScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
), CombinedMetrics AS (
    SELECT 
        U.DisplayName,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(UB.GoldBadges, 0) AS GoldBadges,
        COALESCE(UB.SilverBadges, 0) AS SilverBadges,
        COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(UP.TotalPosts, 0) AS TotalPosts,
        COALESCE(UP.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(UP.TotalComments, 0) AS TotalComments,
        COALESCE(UP.AverageScore, 0) AS AverageScore
    FROM 
        Users U
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN 
        UserPosts UP ON U.Id = UP.OwnerUserId
), TopUsers AS (
    SELECT 
        CM.DisplayName,
        CM.BadgeCount,
        CM.GoldBadges,
        CM.SilverBadges,
        CM.BronzeBadges,
        CM.TotalPosts,
        CM.TotalAnswers,
        CM.TotalComments,
        CM.AverageScore,
        ROW_NUMBER() OVER (ORDER BY CM.TotalPosts DESC, CM.AverageScore DESC) AS Rank
    FROM 
        CombinedMetrics CM
    WHERE 
        CM.TotalPosts > 10
)
SELECT 
    TU.Rank,
    TU.DisplayName,
    TU.BadgeCount,
    TU.GoldBadges,
    TU.SilverBadges,
    TU.BronzeBadges,
    TU.TotalPosts,
    TU.TotalAnswers,
    TU.TotalComments,
    TU.AverageScore,
    PT.TagName,
    PT.TotalViews,
    PT.PostCount
FROM 
    TopUsers TU
LEFT JOIN 
    PopularTags PT ON TU.TotalPosts > 10
WHERE 
    PT.TotalViews IS NOT NULL
ORDER BY 
    TU.Rank;
