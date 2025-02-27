WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- BountyStart, BountyClose
    WHERE 
        p.Score > 0 AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        STRING_AGG(ct.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ct ON ph.Comment::jsonb->>'CloseReasonId'::int = ct.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId, ph.CreationDate
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Rank,
    rp.CommentCount,
    rp.TotalBounty,
    cp.CloseDate,
    cp.CloseReasons
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    (rp.Rank <= 3 OR cp.CloseDate IS NOT NULL)
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
