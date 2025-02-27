WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS Owner,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days' 
        AND p.Score IS NOT NULL
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        ph.PostHistoryTypeId,
        p.Title
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
        AND ph.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    GROUP BY 
        rp.PostId, rp.Title, rp.Score
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.CommentCount,
    ps.TotalBounty,
    CASE 
        WHEN cp.PostId IS NOT NULL THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus,
    COALESCE(NULLIF(u.EmailHash, ''), 'No Email') AS UserEmailHash
FROM 
    PostStatistics ps
LEFT JOIN 
    ClosedPosts cp ON ps.PostId = cp.PostId
LEFT JOIN 
    Users u ON ps.PostId = u.Id
WHERE 
    ps.Score > 5
ORDER BY 
    ps.Score DESC, 
    ps.CommentCount DESC
LIMIT 100;
