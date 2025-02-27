
WITH UserBadges AS (
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
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        @row_number := IF(@prev_owner_user_id = P.OwnerUserId, @row_number + 1, 1) AS Rnk,
        @prev_owner_user_id := P.OwnerUserId
    FROM Posts P
    JOIN (SELECT @row_number := 0, @prev_owner_user_id := NULL) AS vars
    WHERE P.Score > 0
    ORDER BY P.OwnerUserId, P.Score DESC
),
PostMetrics AS (
    SELECT 
        U.DisplayName,
        SUM(P.Score) AS TotalScore,
        COUNT(P.Id) AS TotalPosts,
        AVG(P.ViewCount) AS AvgViewCount,
        SUM(P.AnswerCount) AS TotalAnswers
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.DisplayName
),
CombinedMetrics AS (
    SELECT 
        UB.UserId,
        UB.DisplayName,
        PM.TotalScore,
        PM.TotalPosts,
        PM.AvgViewCount,
        PM.TotalAnswers,
        UB.BadgeCount,
        UB.GoldBadges,
        UB.SilverBadges,
        UB.BronzeBadges
    FROM UserBadges UB
    JOIN PostMetrics PM ON UB.DisplayName = PM.DisplayName
)
SELECT 
    CM.DisplayName,
    CM.TotalScore,
    CM.TotalPosts,
    CM.AvgViewCount,
    CM.TotalAnswers,
    CM.BadgeCount,
    CM.GoldBadges,
    CM.SilverBadges,
    CM.BronzeBadges,
    PP.Title AS PopularPostTitle
FROM CombinedMetrics CM
LEFT JOIN PopularPosts PP ON CM.UserId = PP.OwnerUserId AND PP.Rnk = 1
ORDER BY CM.TotalScore DESC, CM.BadgeCount DESC
LIMIT 10;
