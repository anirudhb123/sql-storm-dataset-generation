WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.ClosedDate,
        p.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    INNER JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 -- Questions only
),
TopClosures AS (
    SELECT 
        ph.PostId, 
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT crt.Name, ', ') AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON ph.Comment = crt.Id::text
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Post Closed or Reopened
    GROUP BY 
        ph.PostId
),
PostMetrics AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        COALESCE(tc.CloseCount, 0) AS CloseCount,
        COALESCE(tc.CloseReason, 'None') AS CloseReason,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        TopClosures tc ON rp.Id = tc.PostId
)
SELECT 
    pm.Title,
    pm.OwnerDisplayName,
    pm.CreationDate,
    pm.Score,
    pm.ViewCount,
    pm.CloseCount,
    pm.CloseReason,
    CASE 
        WHEN pm.CloseCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    (SELECT AVG(Score) FROM Posts WHERE OwnerUserId = pm.OwnerUserId) AS AvgScoreByUser,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = pm.Id AND v.VoteTypeId = 2) AS Upvotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = pm.Id AND v.VoteTypeId = 3) AS Downvotes,
    DENSE_RANK() OVER (ORDER BY pm.Score DESC) AS ScoreRank
FROM 
    PostMetrics pm
WHERE 
    pm.Score > 0 -- Exclude posts with zero score
ORDER BY 
    pm.Score DESC,
    pm.CreationDate DESC
FETCH FIRST 50 ROWS ONLY;
