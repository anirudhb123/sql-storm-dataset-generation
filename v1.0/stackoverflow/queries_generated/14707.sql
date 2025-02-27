-- Performance Benchmarking Query
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.Reputation
),
PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COUNT(C.ID) AS CommentCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.PostTypeId, P.CreationDate, P.ViewCount, P.Score
),
TopUsers AS (
    SELECT 
        UR.UserId,
        UR.Reputation,
        UR.PostCount,
        UR.TotalScore,
        ROW_NUMBER() OVER (ORDER BY UR.Reputation DESC) AS Rank
    FROM UserReputation UR
    WHERE UR.PostCount > 0
)
SELECT 
    PU.UserId,
    PU.Reputation,
    PU.PostCount,
    PU.TotalScore,
    PM.PostId,
    PM.PostTypeId,
    PM.CreationDate,
    PM.ViewCount,
    PM.Score,
    PM.CommentCount,
    PM.TotalBounty,
    TU.Rank
FROM PostMetrics PM
JOIN Users PU ON PM.PostId IN (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = PU.Id)
JOIN TopUsers TU ON PU.Id = TU.UserId
ORDER BY TU.Rank, PM.Score DESC;
