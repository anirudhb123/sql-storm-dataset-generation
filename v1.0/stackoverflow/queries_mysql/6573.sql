
WITH UserBadgeCounts AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
),
TopUsers AS (
    SELECT U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.LastAccessDate, COALESCE(UBC.BadgeCount, 0) AS BadgeCount
    FROM Users U
    LEFT JOIN UserBadgeCounts UBC ON U.Id = UBC.UserId
    WHERE U.Reputation > 1000
    ORDER BY U.Reputation DESC
    LIMIT 10
),
PostStats AS (
    SELECT P.OwnerUserId, COUNT(P.Id) AS PostCount, SUM(P.ViewCount) AS TotalViews, AVG(P.Score) AS AvgScore
    FROM Posts P
    WHERE P.CreationDate >= '2023-10-01 12:34:56'
    GROUP BY P.OwnerUserId
),
CombinedStats AS (
    SELECT TU.Id AS UserId, TU.DisplayName, TU.Reputation, TU.CreationDate, TU.LastAccessDate, TU.BadgeCount,
           COALESCE(PS.PostCount, 0) AS PostCount, COALESCE(PS.TotalViews, 0) AS TotalViews, COALESCE(PS.AvgScore, 0) AS AvgScore
    FROM TopUsers TU
    LEFT JOIN PostStats PS ON TU.Id = PS.OwnerUserId
)
SELECT CS.UserId, CS.DisplayName, CS.Reputation, CS.CreationDate, CS.LastAccessDate, CS.BadgeCount,
       CS.PostCount, CS.TotalViews, CS.AvgScore,
       @views_rank := IF(@prev_views = CS.TotalViews, @views_rank, @rank_no) AS ViewsRank,
       @prev_views := CS.TotalViews,
       @rank_no := @rank_no + 1 AS dummy1,
       @score_rank := IF(@prev_score = CS.AvgScore, @score_rank, @rank_no_score) AS ScoreRank,
       @prev_score := CS.AvgScore,
       @rank_no_score := @rank_no_score + 1 AS dummy2
FROM CombinedStats CS,
(SELECT @views_rank := 0, @prev_views := NULL, @rank_no := 1, @score_rank := 0, @prev_score := NULL, @rank_no_score := 1) AS Init
ORDER BY CS.Reputation DESC, CS.BadgeCount DESC;
