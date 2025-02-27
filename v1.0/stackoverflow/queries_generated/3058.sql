WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Only recent posts
),

TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.ViewCount, 
        rp.Score, 
        rp.UserRank, 
        rp.CommentCount,
        rp.TotalBounty
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserRank = 1 -- Top post per user
)

SELECT 
    u.DisplayName,
    tp.Title,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    COALESCE(tp.TotalBounty, 0) AS Bounty
FROM 
    Users u
RIGHT JOIN 
    TopPosts tp ON u.Id = tp.OwnerUserId
WHERE 
    u.Reputation >= 1000 -- Only users with reputation >= 1000
    AND (tp.ViewCount > 50 OR tp.Score > 10) -- High engagement filter
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC

UNION ALL

SELECT 
    NULL AS DisplayName,
    'No Top Posts' AS Title,
    0 AS ViewCount,
    0 AS Score,
    0 AS CommentCount,
    0 AS Bounty
FROM 
    dual
WHERE 
    NOT EXISTS (SELECT 1 FROM TopPosts);
