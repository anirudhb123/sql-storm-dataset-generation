WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.ViewCount,
        COALESCE(COUNT(C.ID), 0) AS CommentCount,
        SUM(PH.PostHistoryTypeId IN (10, 11)) AS ClosureCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    GROUP BY P.Id, P.Title, P.OwnerUserId, P.ViewCount
),
TopPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.ViewCount,
        RANK() OVER (ORDER BY PS.ViewCount DESC) AS ViewRank
    FROM PostStatistics PS
    WHERE PS.ViewCount > 100
),
FinalResults AS (
    SELECT 
        T.Title,
        T.ViewCount,
        U.DisplayName,
        U.VoteCount,
        U.UpVotes,
        U.DownVotes,
        COALESCE(TC.ClosureCount, 0) AS TotalClosures
    FROM TopPosts T
    JOIN Users U ON T.OwnerUserId = U.Id
    LEFT JOIN PostStatistics TC ON T.PostId = TC.PostId
    WHERE U.Reputation > 1000
)
SELECT 
    FR.Title AS PostTitle,
    FR.ViewCount,
    FR.DisplayName AS Owner,
    FR.VoteCount,
    FR.UpVotes,
    FR.DownVotes,
    FR.TotalClosures
FROM FinalResults FR
WHERE FR.TotalClosures IS NOT NULL
ORDER BY FR.ViewCount DESC, FR.UpVotes DESC;
