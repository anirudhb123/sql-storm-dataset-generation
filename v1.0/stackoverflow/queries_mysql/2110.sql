
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(P.AnswerCount) AS TotalAnswers,
        AVG(P.Score) AS AverageScore
    FROM Posts P
    WHERE P.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY P.OwnerUserId
),
RankedUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        UB.BadgeCount,
        PS.TotalPosts,
        PS.TotalAnswers,
        PS.AverageScore,
        @postRank := IFNULL(@postRank + 1, 1) AS PostRank,
        @badgeRank := IFNULL(@badgeRank + 1, 1) AS BadgeRank
    FROM Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
    CROSS JOIN (SELECT @postRank := NULL, @badgeRank := NULL) r
    ORDER BY PS.TotalPosts DESC, UB.BadgeCount DESC
)
SELECT 
    R.DisplayName,
    COALESCE(R.BadgeCount, 0) AS BadgeCount,
    COALESCE(R.TotalPosts, 0) AS TotalPosts,
    COALESCE(R.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(R.AverageScore, 0) AS AverageScore,
    CASE 
        WHEN R.BadgeRank IS NULL AND R.PostRank IS NULL THEN 'No Activity'
        WHEN R.BadgeRank = 1 THEN 'Top User by Badges'
        WHEN R.PostRank = 1 THEN 'Top User by Posts'
        ELSE 'Normal User'
    END AS UserStatus
FROM RankedUsers R
LEFT JOIN Posts P ON P.OwnerUserId = R.Id
WHERE R.TotalPosts > 0 OR R.BadgeCount > 0
ORDER BY R.PostRank, R.BadgeRank;
