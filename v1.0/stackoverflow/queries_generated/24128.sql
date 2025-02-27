WITH UserBadgeStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) FILTER (WHERE B.Class = 1) AS GoldBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 2) AS SilverBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 3) AS BronzeBadges,
        SUM(B.Class) AS TotalBadgeClass,
        DENSE_RANK() OVER (ORDER BY SUM(B.Class) DESC) AS BadgeRank
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostStatistics AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        Coalesce(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        Coalesce(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(C.Id) AS CommentCount,
        COUNT(DISTINCT PH.Id) FILTER (WHERE PH.PostHistoryTypeId = 10 /* Post Closed */) AS TimesClosed
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    GROUP BY P.Id, P.Title, P.ViewCount
),
TopPostUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        P.Id AS PostId,
        PS.UpVotes,
        PS.DownVotes,
        PS.ViewCount,
        PS.TimesClosed,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY PS.ViewCount DESC) AS PostRank
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    JOIN PostStatistics PS ON P.Id = PS.PostId
    WHERE U.Reputation > 10000
)
SELECT 
    UBS.UserId,
    UBS.DisplayName,
    UBS.GoldBadges,
    UBS.SilverBadges,
    UBS.BronzeBadges,
    P.UserId AS TopPostUserId,
    COUNT(P.PostId) AS TotalPosts,
    SUM(P.ViewCount) AS AggregateViews,
    MAX(P.DownVotes) AS HighestDownVotes,
    COUNT(CASE WHEN P.TimesClosed > 0 THEN 1 END) AS ClosedPostsCount
FROM UserBadgeStats UBS
LEFT JOIN TopPostUsers P ON UBS.UserId = P.UserId AND P.PostRank <= 5
GROUP BY UBS.UserId, UBS.DisplayName, P.UserId
HAVING COUNT(P.PostId) > 0
ORDER BY AggregateViews DESC
LIMIT 10;

-- Bonus: Include some NULL logic and odd semantics
SELECT 
    COALESCE(UBS.DisplayName, 'Anonymous') AS UserAlias,
    COALESCE(UBS.GoldBadges, 0) + COALESCE(P.OtherBadges, 0) AS TotalAchievements,
    CASE WHEN SUM(P.DownVotes) = 0 THEN 'No Downvotes' ELSE 'Has Downvotes' END AS VoteStatus,
    CASE WHEN AVG(PS.ViewCount) IS NULL THEN 'No Posts Viewed' ELSE 'Posts Viewed' END AS ViewSummary 
FROM UserBadgeStats UBS
LEFT JOIN PostStatistics PS ON UBS.UserId = PS.PostId
GROUP BY UBS.UserId;
