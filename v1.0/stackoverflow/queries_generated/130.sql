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
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY P.OwnerUserId
),
RecentComments AS (
    SELECT 
        C.UserId,
        COUNT(C.Id) AS CommentCount
    FROM Comments C
    WHERE C.CreationDate >= NOW() - INTERVAL '30 days'
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
    STRING_AGG(DISTINCT tags.TagName, ', ') AS AssociatedTags
FROM UserPostBadge UPB
LEFT JOIN Posts P ON UPB.UserId = P.OwnerUserId
LEFT JOIN LATERAL (
    SELECT DISTINCT UNNEST(string_to_array(P.Tags, '><')) AS TagName
) AS tags ON TRUE
GROUP BY U.DisplayName, UPB.PostCount, UPB.RecentCommentCount, UPB.BadgeCount, UPB.GoldBadgeCount, UPB.SilverBadgeCount, UPB.BronzeBadgeCount
ORDER BY UPB.BadgeCount DESC, UPB.PostCount DESC
LIMIT 50;
