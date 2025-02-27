WITH UserReputation AS (
    SELECT 
        Id AS UserId, 
        Reputation,
        COUNT(CASE WHEN UpVotes > DownVotes THEN 1 END) AS UpvoteScore,
        COUNT(CASE WHEN DownVotes > UpVotes THEN 1 END) AS DownvoteScore
    FROM Users
    GROUP BY Id, Reputation
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN P.ParentId IS NOT NULL THEN 1 END) AS AnswerCount,
        P.Score,
        P.Title,
        P.CreationDate
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.Id, P.OwnerUserId, P.Score, P.Title, P.CreationDate
),
TopPosts AS (
    SELECT 
        PS.PostId,
        PS.OwnerUserId,
        PS.Title,
        PS.Score,
        PS.UpVotes - PS.DownVotes AS NetVotes,
        ROW_NUMBER() OVER (PARTITION BY PS.OwnerUserId ORDER BY PS.Score DESC) AS RowNum
    FROM PostStats PS
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    UR.UpvoteScore,
    UR.DownvoteScore,
    TP.Title, 
    TP.NetVotes,
    TP.Score,
    TP.CreationDate
FROM Users U
LEFT JOIN UserReputation UR ON U.Id = UR.UserId
LEFT JOIN TopPosts TP ON U.Id = TP.OwnerUserId AND TP.RowNum = 1
WHERE U.Reputation > 1000
  AND (UR.UpvoteScore IS NOT NULL OR UR.DownvoteScore IS NOT NULL)
ORDER BY U.Reputation DESC, TP.Score DESC
LIMIT 10;
