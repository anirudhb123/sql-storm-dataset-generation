WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        DENSE_RANK() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.Comment AS CloseReason,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId, ph.Comment
),
ScoredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        COALESCE(cp.CloseCount, 0) AS CloseCount,
        COALESCE(cp.CloseReason, 'N/A') AS CloseReason
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    sp.Title,
    sp.OwnerDisplayName,
    sp.Score,
    sp.CloseCount,
    CASE 
        WHEN sp.CloseCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    (SELECT COUNT(*) 
     FROM Comments c 
     WHERE c.PostId = sp.PostId) AS CommentCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    ScoredPosts sp
LEFT JOIN 
    Posts p ON sp.PostId = p.Id
LEFT JOIN 
    Tags t ON POSITION('>' || t.TagName || '<' IN '<' || p.Tags || '>') > 0 -- Filtering tags
WHERE 
    sp.TagRank <= 3 -- Limiting to top 3 ranked tags
GROUP BY 
    sp.PostId, sp.Title, sp.OwnerDisplayName, sp.Score, sp.CloseCount
ORDER BY 
    sp.Score DESC, sp.CloseCount ASC;
