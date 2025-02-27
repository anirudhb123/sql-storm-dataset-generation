WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN V.CreationDate END) AS VoteTimeliness
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id
),
PostsStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COALESCE(SUM(V.VoteTypeId = 2) - SUM(V.VoteTypeId = 3), 0) AS Score
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.CreationDate,
        PH.Comment,
        PHT.Name AS HistoryType,
        RANK() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE 
        PH.CreationDate < NOW() - INTERVAL '30 days'
),
FilteredPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CommentCount,
        PS.Score,
        UVS.DisplayName,
        PHD.Comment AS LastComment,
        PHD.CreationDate AS LastEditDate,
        PHD.HistoryType
    FROM 
        PostsStats PS
    JOIN 
        UserVoteStats UVS ON PS.CommentCount >= UVS.UpVotes
    LEFT JOIN 
        PostHistoryDetails PHD ON PS.PostId = PHD.PostId AND PHD.HistoryRank = 1
    WHERE 
        (PS.CommentCount > 0 AND PS.Score > 0) OR PS.CommentCount IS NULL
)
SELECT 
    FP.PostId,
    FP.Title,
    FP.CommentCount,
    FP.Score,
    FP.DisplayName,
    COALESCE(FP.LastComment, 'No edits or last comment available') AS LastComment,
    COALESCE(FP.LastEditDate, 'Never') AS LastEditDate,
    COALESCE(FP.HistoryType, 'N/A') AS HistoryType
FROM 
    FilteredPosts FP
WHERE 
    FP.CommentCount IS NOT NULL
ORDER BY 
    FP.Score DESC, FP.CommentCount DESC
LIMIT 100;
