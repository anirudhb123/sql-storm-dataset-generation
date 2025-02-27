
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        @row_num := @row_num + 1 AS ReputationRank
    FROM Users U, (SELECT @row_num := 0) r
    WHERE U.Reputation IS NOT NULL
    ORDER BY U.Reputation DESC
), PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COALESCE(SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END), 0) AS PositiveScores,
        COALESCE(SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END), 0) AS NegativeScores,
        AVG(P.ViewCount) AS AverageViews
    FROM Posts P
    GROUP BY P.OwnerUserId
), UserBadgeCounts AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount
    FROM Badges B
    GROUP BY B.UserId
), CombinedStats AS (
    SELECT 
        U.DisplayName,
        COALESCE(UR.Reputation, 0) AS Reputation,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.PositiveScores, 0) AS PositiveScores,
        COALESCE(PS.NegativeScores, 0) AS NegativeScores,
        COALESCE(UBC.BadgeCount, 0) AS BadgeCount,
        UR.ReputationRank
    FROM Users U
    LEFT JOIN UserReputation UR ON U.Id = UR.UserId
    LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
    LEFT JOIN UserBadgeCounts UBC ON U.Id = UBC.UserId
    WHERE U.Reputation > 0
), FinalResults AS (
    SELECT 
        *,
        (SELECT COUNT(*) FROM CombinedStats C WHERE C.Reputation > CombinedStats.Reputation OR (C.Reputation = CombinedStats.Reputation AND C.BadgeCount > CombinedStats.BadgeCount)) + 1 AS OverallRank
    FROM CombinedStats
)
SELECT 
    DisplayName,
    Reputation,
    TotalPosts,
    PositiveScores,
    NegativeScores,
    BadgeCount,
    OverallRank
FROM FinalResults
WHERE OverallRank <= 10
ORDER BY OverallRank;
