WITH UserVoteStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS VoteBalance
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.AnswerCount,
        P.ViewCount,
        COALESCE(PV.UserId, -1) AS OwnerId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        MAX(PH.CreationDate) AS LastEdited,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RowNum
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (4, 5, 6) -- Edit title, body, or tags
    LEFT JOIN Users PV ON P.OwnerUserId = PV.Id
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY P.Id, PV.UserId
),
TopPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.AnswerCount,
        PS.ViewCount,
        PS.CommentCount,
        PS.LastEdited,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation,
        US.TotalVotes,
        US.VoteBalance
    FROM PostStats PS
    JOIN Users U ON PS.OwnerId = U.Id
    LEFT JOIN UserVoteStatistics US ON U.Id = US.UserId
    WHERE PS.RowNum = 1
    ORDER BY PS.ViewCount DESC
    LIMIT 10
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.AnswerCount,
    TP.ViewCount,
    TP.CommentCount,
    TP.LastEdited,
    TP.OwnerDisplayName,
    TP.Reputation,
    COALESCE(TP.TotalVotes, 0) AS TotalVotes,
    COALESCE(TP.VoteBalance, 0) AS VoteBalance,
    CASE 
        WHEN TP.Reputation >= 1000 THEN 'High Reputation User'
        WHEN TP.Reputation BETWEEN 500 AND 999 THEN 'Medium Reputation User'
        ELSE 'New User'
    END AS UserCategory
FROM TopPosts TP
LEFT JOIN Users U ON TP.OwnerId = U.Id
WHERE TP.CommentCount > 5 OR (TP.AnswerCount > 0 AND TP.ViewCount > 100)
ORDER BY TP.LastEdited DESC, TP.ViewCount DESC;
