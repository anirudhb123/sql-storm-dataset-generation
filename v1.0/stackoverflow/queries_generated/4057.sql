WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        u.Reputation > 1000
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostComments AS (
    SELECT 
        c.PostId, 
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate AS ClosedDate,
        ARRAY_AGG(DISTINCT cr.Name) AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId, ph.CreationDate
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    COALESCE(cp.ClosedDate, 'No Closure') AS ClosedDate,
    COALESCE(cp.CloseReasons, '{}') AS CloseReasons
FROM 
    RankedPosts rp
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE
    rp.rn = 1
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 100;
