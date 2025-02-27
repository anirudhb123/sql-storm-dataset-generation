
WITH UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        @row_number := @row_number + 1 AS ReputationRank
    FROM Users U, (SELECT @row_number := 0) r
    ORDER BY U.Reputation DESC
),
PostStats AS (
    SELECT
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
TopUsers AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        UR.Reputation,
        PS.PostCount,
        PS.TotalViews,
        PS.AverageScore,
        @user_rank := @user_rank + 1 AS UserRank
    FROM UserReputation UR, (SELECT @user_rank := 0) r
    JOIN PostStats PS ON UR.UserId = PS.OwnerUserId
),
RecentPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        COALESCE(COUNT(C.Id), 0) AS CommentCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY P.Id, P.Title, P.CreationDate, P.OwnerUserId
)
SELECT 
    TU.UserId,
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    @global_rank := @global_rank + 1 AS GlobalRank,
    RP.Title,
    RP.CreationDate,
    RP.CommentCount,
    CASE 
        WHEN TU.Reputation > 1000 THEN 'Expert'
        WHEN TU.Reputation BETWEEN 500 AND 1000 THEN 'Intermediate'
        ELSE 'Novice'
    END AS UserLevel
FROM TopUsers TU, (SELECT @global_rank := 0) r
JOIN RecentPosts RP ON TU.UserId = RP.OwnerUserId
WHERE TU.UserRank <= 10
ORDER BY TU.Reputation DESC, RP.CreationDate DESC
LIMIT 5;
