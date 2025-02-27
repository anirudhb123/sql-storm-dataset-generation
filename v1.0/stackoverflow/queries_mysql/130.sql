
WITH UserBadgeCount AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostAggregation AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        MAX(P.CreationDate) AS LatestPostDate
    FROM Posts P
    WHERE P.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY P.OwnerUserId
),
RecentComments AS (
    SELECT 
        C.UserId,
        COUNT(C.Id) AS CommentCount
    FROM Comments C
    WHERE C.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY C.UserId
),
UserPostBadge AS (
    SELECT 
        U.Id AS UserId,
        COALESCE(P.PostCount, 0) AS PostCount,
        COALESCE(R.CommentCount, 0) AS RecentCommentCount,
        COALESCE(B.BadgeCount, 0) AS BadgeCount,
        COALESCE(B.GoldBadgeCount, 0) AS GoldBadgeCount,
        COALESCE(B.SilverBadgeCount, 0) AS SilverBadgeCount,
        COALESCE(B.BronzeBadgeCount, 0) AS BronzeBadgeCount
    FROM Users U
    LEFT JOIN PostAggregation P ON U.Id = P.OwnerUserId
    LEFT JOIN RecentComments R ON U.Id = R.UserId
    LEFT JOIN UserBadgeCount B ON U.Id = B.UserId
)
SELECT 
    UPB.UserId,
    U.DisplayName,
    UPB.PostCount,
    UPB.RecentCommentCount,
    UPB.BadgeCount,
    UPB.GoldBadgeCount,
    UPB.SilverBadgeCount,
    UPB.BronzeBadgeCount,
    CASE 
        WHEN UPB.PostCount > 10 THEN 'Active Contributor'
        WHEN UPB.PostCount > 0 THEN 'Occasional Contributor'
        ELSE 'Non-Contributor'
    END AS ContributionLevel,
    GROUP_CONCAT(DISTINCT tags.TagName SEPARATOR ', ') AS AssociatedTags
FROM UserPostBadge UPB
JOIN Users U ON UPB.UserId = U.Id
LEFT JOIN Posts P ON UPB.UserId = P.OwnerUserId
LEFT JOIN (
    SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', numbers.n), '><', -1) AS TagName
    FROM Posts P
    INNER JOIN (
        SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
        UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10 
        -- You can increase the number of UNION SELECT to cover all tags
    ) numbers ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) >= numbers.n - 1
) AS tags ON TRUE
GROUP BY UPB.UserId, U.DisplayName, UPB.PostCount, UPB.RecentCommentCount, UPB.BadgeCount, UPB.GoldBadgeCount, UPB.SilverBadgeCount, UPB.BronzeBadgeCount
ORDER BY UPB.BadgeCount DESC, UPB.PostCount DESC
LIMIT 50;
