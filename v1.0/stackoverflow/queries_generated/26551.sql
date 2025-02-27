WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(P.Score), 0) AS TotalScore,
        MAX(B.Date) AS LastBadgeDate
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    WHERE U.Reputation > 0
    GROUP BY U.Id
),
PostTags AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Tags,
        UNNEST(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><')) AS Tag
    FROM Posts P
),
TagCount AS (
    SELECT 
        Tag, 
        COUNT(*) AS TagUsage
    FROM PostTags
    GROUP BY Tag
),
ActivityRanking AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.Reputation,
        UA.TotalPosts,
        UA.TotalComments,
        UA.TotalViews,
        UA.TotalScore,
        COUNT(DISTINCT PT.Tag) AS UniqueTagsUsed,
        ROW_NUMBER() OVER (ORDER BY UA.TotalScore DESC, UA.Reputation DESC) AS Rank
    FROM UserActivity UA
    JOIN PostTags PT ON PT.PostId IN (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = UA.UserId)
    GROUP BY UA.UserId, UA.DisplayName, UA.Reputation, UA.TotalPosts, UA.TotalComments, UA.TotalViews, UA.TotalScore
)
SELECT 
    AR.Rank,
    AR.DisplayName,
    AR.TotalPosts,
    AR.TotalComments,
    AR.TotalViews,
    AR.TotalScore,
    AR.UniqueTagsUsed,
    (SELECT COUNT(*) FROM Badges B WHERE B.UserId = AR.UserId) AS BadgeCount,
    MAX(UA.LastBadgeDate) AS LastBadgeDate
FROM ActivityRanking AR
JOIN UserActivity UA ON AR.UserId = UA.UserId
WHERE AR.Rank <= 10
ORDER BY AR.Rank;
