WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(V.Id) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        COALESCE(UPV.UpVotes, 0) AS UpVotes,
        COALESCE(DNV.DownVotes, 0) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        UserVoteStats UPV ON P.OwnerUserId = UPV.UserId
    LEFT JOIN 
        UserVoteStats DNV ON P.OwnerUserId = DNV.UserId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
PostHistoryWithClosed AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        MAX(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN PH.CreationDate END) AS LastCloseOpenDate,
        MAX(CASE WHEN PH.PostHistoryTypeId IN (10) THEN PH.CreationDate END) AS LastClosedDate,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 12) THEN 1 END) AS CloseCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
)
SELECT 
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.Score,
    PD.ViewCount,
    PD.AnswerCount,
    PD.CommentCount,
    PD.UpVotes,
    PD.DownVotes,
    PH.LastCloseOpenDate,
    PH.LastClosedDate,
    PH.CloseCount,
    CASE 
        WHEN PH.CloseCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    CASE 
        WHEN PD.UpVotes - PD.DownVotes >= 0 THEN 'Positive'
        ELSE 'Negative'
    END AS VoteTrend
FROM 
    PostDetails PD
LEFT JOIN 
    PostHistoryWithClosed PH ON PD.PostId = PH.PostId
WHERE 
    (PD.AnswerCount > 0 OR PD.CommentCount > 0)
    AND (PD.ViewCount > 100 OR (PD.Score > 0 AND PD.CreationDate <= NOW() - INTERVAL '1 month'))
ORDER BY 
    PD.CreationDate DESC,
    PD.Score DESC;
