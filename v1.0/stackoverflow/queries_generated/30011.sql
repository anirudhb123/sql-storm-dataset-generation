WITH RecursiveTagStats AS (
    SELECT
        T.Id AS TagId,
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViewCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM Tags T
    LEFT JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY T.Id, T.TagName

    UNION ALL

    SELECT
        T.Id AS TagId,
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViewCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    WHERE P.ParentId IS NOT NULL
    GROUP BY T.Id, T.TagName
),
AggregatedTagStats AS (
    SELECT 
        TagId,
        TagName,
        SUM(PostCount) AS PostCount,
        SUM(TotalViewCount) AS TotalViewCount,
        SUM(TotalScore) AS TotalScore
    FROM RecursiveTagStats
    GROUP BY TagId, TagName
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews,
        MIN(P.CreationDate) AS FirstPostDate,
        MAX(P.CreationDate) AS LastPostDate
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
)

SELECT 
    U.DisplayName,
    U.TotalPosts,
    U.TotalScore,
    U.TotalViews,
    U.FirstPostDate,
    U.LastPostDate,
    B.TotalBadges,
    B.GoldBadges,
    B.SilverBadges,
    B.BronzeBadges,
    T.TagName,
    T.PostCount,
    T.TotalViewCount,
    T.TotalScore
FROM UserPostStats U
JOIN UserBadges B ON U.UserId = B.UserId
LEFT JOIN AggregatedTagStats T ON T.TagId IN (
    SELECT unnest(string_to_array(P.Tags, '<>'))::int
    FROM Posts P
    WHERE P.OwnerUserId = U.UserId
)
WHERE U.TotalPosts > 10
ORDER BY U.TotalScore DESC, U.TotalViews DESC;
