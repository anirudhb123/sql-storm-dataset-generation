WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId = 1
    GROUP BY 
        p.Id
),

TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        CASE 
            WHEN rp.Score > 100 THEN 'High'
            WHEN rp.Score BETWEEN 50 AND 100 THEN 'Medium'
            ELSE 'Low'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)

SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.ScoreCategory,
    COALESCE((SELECT SUM(v.BountyAmount) 
              FROM Votes v 
              WHERE v.PostId = tp.PostId AND v.VoteTypeId = 8), 0) AS TotalBounty,
    STRING_AGG(t.TagName, ', ') AS Tags
FROM 
    TopPosts tp
LEFT JOIN 
    PostsTags pt ON tp.PostId = pt.PostId
LEFT JOIN 
    Tags t ON pt.TagId = t.Id
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.CommentCount, tp.ScoreCategory
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
