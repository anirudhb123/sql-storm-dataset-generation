WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(b.Class, 0) AS BadgeClass
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId AND b.Date = (
            SELECT MAX(Date) FROM Badges WHERE UserId = u.Id
        )
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.Score > 5
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        ph.Comment AS CloseReason,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY 
        ph.PostId, ph.CreationDate, ph.Comment
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.DisplayName,
    rp.Rank,
    CASE WHEN cp.CloseCount IS NOT NULL THEN 'Closed' ELSE 'Open' END AS Status,
    cp.ClosedDate,
    cp.CloseReason,
    pc.CommentCount
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
WHERE 
    rp.Rank <= 5 -- Top 5 posts per type
ORDER BY 
    rp.PostTypeId, rp.Rank;
