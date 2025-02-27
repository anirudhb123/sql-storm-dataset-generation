WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN V.VoteTypeId IN (6, 10) THEN 1 END) AS CloseVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE -1 END) AS NetVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
),
PostCommentStats AS (
    SELECT
        P.Id AS PostId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        AVG(COALESCE(C.Score, 0)) AS AvgCommentScore,
        SUM(COALESCE(C.Score, 0)) AS TotalCommentScore
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '1 year') -- Only recent posts
    GROUP BY 
        P.Id
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        STRING_AGG(DISTINCT PHT.Name, ', ' ORDER BY PHT.Name) AS HistoryTypes,
        MAX(PH.CreationDate) AS LastHistoryDate,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
),
FinalStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        V.UpVotes,
        V.DownVotes,
        V.CloseVotes,
        PCS.CommentCount,
        PCS.AvgCommentScore,
        PHD.HistoryTypes,
        PHD.LastHistoryDate,
        PHD.CloseCount,
        PHD.ReopenCount,
        CASE 
            WHEN V.NetVotes > 0 THEN 'Positive'
            WHEN V.NetVotes < 0 THEN 'Negative'
            ELSE 'Neutral' 
        END AS VoteSentiment
    FROM 
        Users U
    LEFT JOIN 
        UserVoteStats V ON U.Id = V.UserId
    LEFT JOIN 
        PostCommentStats PCS ON U.Id IN (SELECT OwnerUserId FROM Posts WHERE OwnerUserId IS NOT NULL)
    LEFT JOIN 
        PostHistoryDetails PHD ON PHD.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = U.Id)
    WHERE 
        U.Reputation > 1000 -- Consider users with decent reputation
)

SELECT 
    FS.UserId,
    FS.DisplayName,
    FS.Reputation,
    FS.CreationDate,
    FS.UpVotes,
    FS.DownVotes,
    FS.CloseVotes,
    FS.CommentCount,
    FS.AvgCommentScore,
    FS.HistoryTypes,
    FS.LastHistoryDate,
    FS.CloseCount,
    FS.ReopenCount,
    FS.VoteSentiment
FROM 
    FinalStats FS
ORDER BY 
    FS.Reputation DESC,
    FS.UpVotes DESC,
    FS.CommentCount DESC
LIMIT 50;

-- Add a bizarre edge case: Check for users who have never been active in delete/reopen actions 
HAVING 
    FS.CloseCount = 0 AND FS.ReopenCount = 0

