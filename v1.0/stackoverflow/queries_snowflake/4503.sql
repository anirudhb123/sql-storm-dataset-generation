
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
),
PostVoteCounts AS (
    SELECT 
        PostId, 
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVoteCount
    FROM 
        Votes
    GROUP BY 
        PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseReasonCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) AND
        ph.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '6 months'
    GROUP BY 
        ph.PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.Score,
    RP.ViewCount,
    RP.OwnerDisplayName,
    PVC.UpVoteCount,
    PVC.DownVoteCount,
    COALESCE(CP.CloseReasonCount, 0) AS CloseReasonCount
FROM 
    RankedPosts RP
LEFT JOIN 
    PostVoteCounts PVC ON RP.PostId = PVC.PostId
LEFT JOIN 
    ClosedPosts CP ON RP.PostId = CP.PostId
WHERE 
    RP.ScoreRank <= 5
ORDER BY 
    RP.Score DESC, 
    RP.ViewCount DESC
LIMIT 10;
