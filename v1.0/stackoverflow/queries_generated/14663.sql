-- Performance Benchmarking Query
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(V.BountyAmount) AS TotalBountyAmount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.Reputation
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        COUNT(C.Id) AS CommentCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.Id, P.Score, P.ViewCount, P.AnswerCount, P.CommentCount
),
TopUsers AS (
    SELECT
        US.UserId,
        US.Reputation,
        US.PostCount,
        US.BadgeCount,
        US.TotalBountyAmount,
        RANK() OVER (ORDER BY US.Reputation DESC) AS ReputationRank
    FROM UserStatistics US
)
SELECT 
    TU.UserId,
    TU.Reputation,
    TU.PostCount,
    TU.BadgeCount,
    TU.TotalBountyAmount,
    PS.PostId,
    PS.Score,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount,
    TU.ReputationRank
FROM TopUsers TU
JOIN PostStatistics PS ON PS.PostId IN (
    SELECT P.Id
    FROM Posts P
    WHERE P.OwnerUserId = TU.UserId
)
WHERE TU.ReputationRank <= 10  -- Limit to top 10 users by reputation
ORDER BY TU.Reputation DESC, PS.Score DESC;
