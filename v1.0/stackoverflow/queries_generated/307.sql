WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Score > 0
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        rn <= 10
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        ph.Comment AS CloseReason,
        COUNT(v.Id) AS CloseVoteCount
    FROM 
        PostHistory ph
    LEFT JOIN 
        Votes v ON ph.PostId = v.PostId AND v.VoteTypeId = 6
    WHERE 
        ph.PostHistoryTypeId = 10 
        AND ph.CreationDate >= NOW() - INTERVAL '6 months'
    GROUP BY 
        ph.PostId, ph.CreationDate, ph.Comment
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    COALESCE(cp.ClosedDate, 'Not Closed') AS ClosedDate,
    COALESCE(cp.CloseReason, 'N/A') AS CloseReason,
    COALESCE(cp.CloseVoteCount, 0) AS CloseVoteCount
FROM 
    TopPosts tp
LEFT JOIN 
    ClosedPosts cp ON tp.PostId = cp.PostId
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;
