WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) as Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
),

CloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasonNames
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
),

PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.LastActivityDate,
        rp.Score,
        rp.ViewCount,
        rp.Tags,
        rp.OwnerDisplayName,
        COALESCE(cr.CloseReasonNames, 'No close reason') AS CloseReasonNames
    FROM 
        RankedPosts rp
    LEFT JOIN 
        CloseReasons cr ON rp.PostId = cr.PostId
)

SELECT 
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.LastActivityDate,
    pm.Score,
    pm.ViewCount,
    pm.Tags,
    pm.OwnerDisplayName,
    pm.CloseReasonNames,
    AVG(v.UserId) OVER (PARTITION BY pm.PostId) AS AvgVotes,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = pm.PostId) AS CommentCount
FROM 
    PostMetrics pm
WHERE 
    pm.Rank <= 5
ORDER BY 
    pm.Score DESC, pm.ViewCount DESC;
