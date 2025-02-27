WITH UserBadges AS (
    SELECT U.Id AS UserId, U.DisplayName, COUNT(B.Id) AS BadgeCount, SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges, SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostStatistics AS (
    SELECT P.OwnerUserId, COUNT(C.Id) AS CommentCount, SUM(P.Score) AS TotalScore, COUNT(DISTINCT P.Id) AS PostCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.OwnerUserId
),
CombinedData AS (
    SELECT U.Id AS UserId, U.DisplayName, UB.BadgeCount, UB.GoldBadges, UB.SilverBadges, UB.BronzeBadges,
           PS.CommentCount, PS.TotalScore, PS.PostCount
    FROM Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN PostStatistics PS ON U.Id = PS.OwnerUserId
)
SELECT UserId, DisplayName, BadgeCount, GoldBadges, SilverBadges, BronzeBadges, CommentCount, TotalScore, PostCount
FROM CombinedData
WHERE BadgeCount > 0 AND PostCount > 5
ORDER BY TotalScore DESC, BadgeCount DESC
LIMIT 10;
