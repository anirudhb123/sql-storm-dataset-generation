WITH RecursiveUserPosts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        1 AS Level
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    WHERE U.Reputation > 1000

    UNION ALL

    SELECT 
        U.Id,
        U.DisplayName,
        P.Id,
        P.Title,
        P.CreationDate,
        P.Score,
        Level + 1
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    JOIN RecursiveUserPosts R ON P.ParentId = R.PostId
    WHERE U.Reputation > 1000
),

PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN C.PostId IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    GROUP BY P.Id
),

RankedPosts AS (
    SELECT 
        PS.PostId,
        PS.UpVotes,
        PS.DownVotes,
        PS.CommentCount,
        PS.CloseCount,
        ROW_NUMBER() OVER (ORDER BY (PS.UpVotes - PS.DownVotes) DESC) AS PostRank
    FROM PostStatistics PS
    WHERE PS.CloseCount = 0
)

SELECT 
    U.DisplayName,
    RP.Title,
    RP.UpVotes,
    RP.DownVotes,
    RP.CommentCount,
    RP.PostRank,
    UP.UserId AS RelatedUserId,
    UP.DisplayName AS RelatedUserDisplayName,
    UP.Level
FROM RankedPosts RP
JOIN RecursiveUserPosts UP ON RP.PostId = UP.PostId
JOIN Users U ON U.Id = UP.UserId
WHERE UP.Level <= 2
ORDER BY RP.PostRank, UP.Level;


