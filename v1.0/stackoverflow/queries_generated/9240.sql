WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY U.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotes,
        DownVotes,
        PostCount,
        CommentCount,
        (UpVotes - DownVotes) AS NetScore
    FROM UserStats
    ORDER BY NetScore DESC
    LIMIT 10
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS OwnerName,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(C.Id) AS CommentCount
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.Id, U.DisplayName
)
SELECT 
    TU.DisplayName AS TopUser,
    TU.UpVotes,
    TU.DownVotes,
    TU.PostCount,
    TU.CommentCount,
    PD.Title AS PostTitle,
    PD.CreationDate AS PostCreationDate,
    PD.Score AS PostScore,
    PD.ViewCount AS PostViewCount,
    PD.CommentCount AS PostCommentCount
FROM TopUsers TU
JOIN PostDetails PD ON TU.UserId = PD.OwnerName
ORDER BY TU.NetScore DESC, PD.ViewCount DESC
LIMIT 5;
