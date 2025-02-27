WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- BountyStart, BountyClose
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
PostHistories AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.CreationDate END) AS LastClosed,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN ph.CreationDate END) AS LastDeleted
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.PostRank,
    rp.CommentCount,
    rp.TotalBounty,
    COALESCE(ph.LastClosed, 'No Closures') AS LastClosed,
    COALESCE(ph.LastDeleted, 'No Deletions') AS LastDeleted
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistories ph ON rp.PostId = ph.PostId
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.Score DESC, rp.CreationDate ASC
LIMIT 10;
