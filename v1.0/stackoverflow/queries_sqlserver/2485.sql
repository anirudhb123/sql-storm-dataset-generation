
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0)
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 5
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    ps.CommentCount,
    ps.TotalBounty,
    CASE 
        WHEN ps.TotalBounty > 0 THEN 'Has Bounty'
        ELSE 'No Bounty'
    END AS BountyStatus
FROM 
    TopPosts tp
LEFT JOIN 
    PostStats ps ON tp.Id = ps.PostId
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
