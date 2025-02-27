
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalVotes,
        UpVotes,
        DownVotes,
        @UserRank := @UserRank + 1 AS UserRank
    FROM UserVoteStats, (SELECT @UserRank := 0) AS r
    WHERE TotalVotes > 0
    ORDER BY TotalVotes DESC
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        @PostRank := IF(@PrevUserId = P.OwnerUserId, @PostRank + 1, 1) AS PostRank,
        @PrevUserId := P.OwnerUserId
    FROM Posts P, (SELECT @PostRank := 0, @PrevUserId := NULL) AS r
    WHERE P.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 30 DAY)
    ORDER BY P.OwnerUserId, P.CreationDate DESC
)
SELECT 
    TU.DisplayName,
    TU.TotalVotes,
    TU.UpVotes,
    TU.DownVotes,
    RP.Title,
    RP.CreationDate,
    COALESCE((SELECT U.DisplayName FROM Users U WHERE U.Id = RP.OwnerUserId), 'Anonymous') AS PostOwner,
    (SELECT COUNT(C.Id) FROM Comments C WHERE C.PostId = RP.PostId) AS CommentCount
FROM TopUsers TU
LEFT JOIN RecentPosts RP ON TU.UserId = RP.OwnerUserId
WHERE TU.UserRank <= 10
ORDER BY TU.TotalVotes DESC, RP.CreationDate DESC;
