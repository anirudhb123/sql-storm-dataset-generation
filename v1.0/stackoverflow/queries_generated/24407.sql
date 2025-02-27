WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        COALESCE(P.Score, 0) AS Score,
        COALESCE(P.Views, 0) AS Views,
        COUNT(C.ID) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN H.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN H.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Badges B ON B.UserId = P.OwnerUserId
    LEFT JOIN PostHistory H ON P.Id = H.PostId
    GROUP BY P.Id
),
RankedPosts AS (
    SELECT 
        PS.PostId,
        PS.PostTypeId,
        PS.Score,
        PS.Views,
        PS.CommentCount,
        PS.BadgeCount,
        PS.CloseCount,
        PS.ReopenCount,
        RANK() OVER (PARTITION BY PS.PostTypeId ORDER BY PS.Score DESC, PS.Views DESC) AS ScoreRank
    FROM PostStatistics PS
),
TopRankedPosts AS (
    SELECT 
        RP.PostId,
        RP.PostTypeId,
        RP.Score,
        RP.Views,
        RP.CommentCount,
        RP.BadgeCount,
        RP.CloseCount,
        RP.ReopenCount
    FROM RankedPosts RP
    WHERE RP.ScoreRank <= 5
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(UVC.TotalVotes, 0) AS TotalVotes,
        COALESCE(UVC.UpVotes, 0) AS UpVotes,
        COALESCE(UVC.DownVotes, 0) AS DownVotes
    FROM Users U
    LEFT JOIN UserVoteCounts UVC ON U.Id = UVC.UserId
)
SELECT 
    PS.PostId,
    PS.PostTypeId,
    PS.Score,
    PS.Views,
    PS.CommentCount,
    PS.BadgeCount,
    PS.CloseCount,
    PS.ReopenCount,
    US.DisplayName AS OwnerDisplayName,
    US.Reputation,
    US.TotalVotes,
    US.UpVotes,
    US.DownVotes
FROM TopRankedPosts PS
LEFT JOIN UserStats US ON PS.PostId IN (
    SELECT P.Id FROM Posts P WHERE P.OwnerUserId = US.UserId
)
ORDER BY PS.Score DESC, PS.Views DESC, US.Reputation DESC;
