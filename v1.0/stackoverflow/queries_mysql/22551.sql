
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS TotalBadges,
        MAX(B.Class) AS HighestBadgeClass,
        GROUP_CONCAT(B.Name ORDER BY B.Name SEPARATOR ', ') AS BadgeNames
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.ViewCount,
        P.Score,
        @row_number := IF(@prev_user = P.OwnerUserId, @row_number + 1, 1) AS PostRank,
        @prev_user := P.OwnerUserId,
        CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '<>', '')) + 1 AS TagCount
    FROM Posts P, (SELECT @row_number := 0, @prev_user := NULL) AS vars
    WHERE P.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 30 DAY
    ORDER BY P.OwnerUserId, P.CreationDate DESC
),
PostTags AS (
    SELECT 
        P.Id AS PostId,
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM Posts P
    JOIN Tags T ON FIND_IN_SET(T.TagName, P.Tags) > 0
    GROUP BY P.Id, T.TagName
),
UserPostStatistics AS (
    SELECT 
        UB.UserId,
        UB.DisplayName,
        COUNT(RP.PostId) AS RecentPostCount,
        COALESCE(SUM(CASE WHEN RP.Score > 0 THEN 1 ELSE 0 END), 0) AS PositivePostCount,
        COALESCE(AVG(RP.ViewCount), 0) AS AvgViewCount,
        COALESCE(SUM(PT.PostCount), 0) AS TotalTaggedCount
    FROM UserBadges UB
    LEFT JOIN RecentPosts RP ON UB.UserId = RP.OwnerUserId
    LEFT JOIN PostTags PT ON PT.PostId = RP.PostId
    GROUP BY UB.UserId, UB.DisplayName
),
CombinedStats AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.TotalBadges,
        U.HighestBadgeClass,
        UPS.RecentPostCount,
        UPS.PositivePostCount,
        UPS.AvgViewCount,
        UPS.TotalTaggedCount
    FROM UserBadges U
    JOIN UserPostStatistics UPS ON U.UserId = UPS.UserId
)
SELECT 
    CS.DisplayName,
    CS.TotalBadges,
    CASE 
        WHEN CS.HighestBadgeClass = 1 THEN 'Gold'
        WHEN CS.HighestBadgeClass = 2 THEN 'Silver'
        WHEN CS.HighestBadgeClass = 3 THEN 'Bronze'
        ELSE 'None'
    END AS BadgeType,
    CS.RecentPostCount,
    CS.PositivePostCount,
    ROUND(CS.AvgViewCount, 2) AS AverageViews,
    CS.TotalTaggedCount,
    CASE 
        WHEN CS.RecentPostCount = 0 THEN NULL
        ELSE ROUND((CAST(CS.PositivePostCount AS DECIMAL) / CS.RecentPostCount) * 100, 2) 
    END AS PositivePostPercentage
FROM CombinedStats CS
WHERE (CS.RecentPostCount > 0 OR CS.TotalBadges > 0)
ORDER BY CS.TotalBadges DESC, CS.AvgViewCount DESC;
