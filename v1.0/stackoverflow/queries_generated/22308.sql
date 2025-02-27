WITH UserBadgeCount AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
RecentPosts AS (
    SELECT 
        P.OwnerUserId,
        P.PostTypeId,
        COUNT(C.Id) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBounty 
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9)  -- bounty start or bounty close
    WHERE P.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY P.OwnerUserId, P.PostTypeId 
),
PerformanceStats AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        COALESCE(RC.CommentCount, 0) AS RecentCommentCount,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(UB.GoldBadges, 0) AS GoldBadges,
        COALESCE(UB.SilverBadges, 0) AS SilverBadges,
        COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
        SUM(COALESCE(RP.TotalBounty, 0)) AS TotalBounty
    FROM UserBadgeCount UB
    LEFT JOIN RecentPosts RP ON UB.UserId = RP.OwnerUserId
    LEFT JOIN Users U ON UB.UserId = U.Id
    GROUP BY U.UserId, U.DisplayName
),
RankedUsers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY TotalBounty DESC, BadgeCount DESC) AS UserRank
    FROM PerformanceStats
)

SELECT 
    DisplayName, 
    RecentCommentCount, 
    BadgeCount, 
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    TotalBounty,
    UserRank
FROM RankedUsers
WHERE UserRank <= 50 
ORDER BY TotalBounty DESC, BadgeCount DESC
OPTION (RECOMPILE);

This SQL query performs a complex series of operations to generate a ranking of users based on their badge counts and the total bounty amounts on their recent posts over the last 30 days. The use of Common Table Expressions (CTEs) enables legibility and step-wise aggregation—first counting badges, then aggregating recent posts with their comments and bounties, and finally calculating overall performance statistics. The final query returns the top users while ensuring proper ranking is maintained. The `OPTION (RECOMPILE)` hint is used for performance benchmarking purposes, allowing the database engine to re-evaluate the plan for varied parameter inputs.
