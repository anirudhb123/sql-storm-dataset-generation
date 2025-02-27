WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS ScoreRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id AND v.VoteTypeId = 8  -- BountyStart
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastClosedDate,
        COUNT(*) AS ClosureCount
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON ph.PostId = p.Id AND ph.PostHistoryTypeId = 10  -- Post Closed
    GROUP BY 
        p.Id
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.ScoreRank,
        rp.CommentCount,
        rp.TotalBounty,
        cp.LastClosedDate,
        cp.ClosureCount,
        CASE 
            WHEN cp.ClosureCount > 0 THEN 'Closed'
            ELSE 'Open'
        END AS PostStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON cp.PostId = rp.PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.ScoreRank,
    pd.CommentCount,
    pd.TotalBounty,
    pd.LastClosedDate,
    pd.ClosureCount,
    pd.PostStatus
FROM 
    PostDetails pd
WHERE 
    pd.ScoreRank = 1 AND
    pd.CommentCount > 5 AND
    (pd.TotalBounty > 0 OR pd.PostStatus = 'Closed')
ORDER BY 
    pd.Score DESC, pd.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
