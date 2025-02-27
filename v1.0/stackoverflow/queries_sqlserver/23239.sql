
WITH UserProfileStats AS (
    SELECT 
        U.Id as UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.Location,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers,
        SUM(ISNULL(P.ViewCount, 0)) AS TotalViews,
        SUM(ISNULL(P.Score, 0)) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 0
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.Location
), RecentPostActivities AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        PH.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) as ActivityRank,
        PH.Comment
    FROM 
        PostHistory PH
    WHERE 
        PH.CreationDate > CAST('2024-10-01 12:34:56' AS datetime) - INTERVAL '30 days'
), UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges B
    WHERE 
        B.Date >= CAST('2024-10-01 12:34:56' AS datetime) - INTERVAL '1 year'
    GROUP BY 
        B.UserId
), UserComments AS (
    SELECT 
        C.UserId,
        COUNT(*) AS TotalComments,
        SUM(CASE WHEN C.Score < 0 THEN 1 ELSE 0 END) AS NegativeComments
    FROM 
        Comments C
    GROUP BY 
        C.UserId
), UserEngagement AS (
    SELECT 
        UPS.UserId,
        UPS.DisplayName,
        UPS.Reputation,
        UPS.TotalPosts,
        UPS.TotalQuestions,
        UPS.TotalAnswers,
        UPS.TotalViews,
        UPS.TotalScore,
        ISNULL(UB.GoldBadges, 0) AS GoldBadges,
        ISNULL(UB.SilverBadges, 0) AS SilverBadges,
        ISNULL(UB.BronzeBadges, 0) AS BronzeBadges,
        ISNULL(UC.TotalComments, 0) AS TotalComments,
        ISNULL(UC.NegativeComments, 0) AS NegativeComments,
        RPA.ActivityRank,
        RPA.Comment as RecentActivityComment
    FROM 
        UserProfileStats UPS
    LEFT JOIN 
        UserBadges UB ON UPS.UserId = UB.UserId
    LEFT JOIN 
        UserComments UC ON UPS.UserId = UC.UserId
    LEFT JOIN 
        RecentPostActivities RPA ON UPS.UserId = RPA.UserId 
    WHERE 
        UPS.TotalPosts > 10 AND 
        (UPS.Reputation > 100 OR UPS.TotalQuestions > 5)
)
SELECT 
    *
FROM 
    UserEngagement
WHERE 
    (GoldBadges + SilverBadges + BronzeBadges) > 1
ORDER BY 
    TotalScore DESC;
