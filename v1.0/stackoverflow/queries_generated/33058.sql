WITH RecursiveTagCount AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM Tags T
    LEFT JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY T.Id, T.TagName
),
UserPostStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN P.Score > 0 THEN P.Score ELSE 0 END) AS TotalScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
UserBadgeCount AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgesCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgesCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgesCount
    FROM Badges B
    GROUP BY B.UserId
),
PostHistoryChangeTypes AS (
    SELECT 
        PH.PostId,
        MAX(CASE WHEN PH.PostHistoryTypeId IN (10, 11, 12) THEN 1 ELSE 0 END) AS HasBeenClosedOrReopened,
        MAX(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedCount,
        MAX(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenedCount
    FROM PostHistory PH
    GROUP BY PH.PostId
)
SELECT 
    U.DisplayName,
    U.TotalPosts,
    U.QuestionsCount,
    U.AnswersCount,
    U.TotalScore,
    COALESCE(UBC.TotalBadges, 0) AS TotalBadges,
    COALESCE(UBC.GoldBadgesCount, 0) AS GoldBadgesCount,
    COALESCE(UBC.SilverBadgesCount, 0) AS SilverBadgesCount,
    COALESCE(UBC.BronzeBadgesCount, 0) AS BronzeBadgesCount,
    RT.TagName,
    RT.PostCount,
    PH.HasBeenClosedOrReopened,
    PH.ClosedCount,
    PH.ReopenedCount
FROM UserPostStatistics U
LEFT JOIN UserBadgeCount UBC ON U.Id = UBC.UserId
LEFT JOIN RecursiveTagCount RT ON RT.PostCount > 0
LEFT JOIN PostHistoryChangeTypes PH ON PH.PostId = (
    SELECT Id 
    FROM Posts 
    WHERE OwnerUserId = U.Id
    ORDER BY CreationDate DESC 
    LIMIT 1)
ORDER BY U.TotalScore DESC, U.TotalPosts DESC;
This complex SQL query combines several constructs, including recursive CTEs for tag counts, aggregate functions for user statistics, and outer joins to combine data from different sources. It fetches user statistics based on their post activity, badges earned, and historical post status. The resulting dataset is sorted by total score and post count, providing a comprehensive overview of user contributions on the platform.
