-- Performance Benchmarking Query
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(V.BountyAmount) AS TotalBounty
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.Reputation, U.CreationDate
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        P.CreationDate AS PostCreationDate,
        COUNT(CM.Id) AS CommentCount,
        COUNT(V.Id) AS VoteCount
    FROM Posts P
    LEFT JOIN Comments CM ON P.Id = CM.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.Title, P.ViewCount, P.Score, P.CreationDate
)
SELECT 
    US.UserId,
    US.Reputation,
    US.CreationDate,
    US.PostCount,
    US.Questions,
    US.Answers,
    US.TotalBounty,
    PD.PostId,
    PD.Title,
    PD.ViewCount,
    PD.Score,
    PD.PostCreationDate,
    PD.CommentCount,
    PD.VoteCount
FROM UserStats US
JOIN PostDetails PD ON US.UserId = PD.OwnerUserId
ORDER BY US.Reputation DESC, PD.ViewCount DESC;
