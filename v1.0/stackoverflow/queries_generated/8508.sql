WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days' 
        AND p.Score > 0
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.CommentCount,
    pt.Name AS PostType,
    CASE 
        WHEN rp.Rank <= 10 THEN 'Top 10'
        WHEN rp.Rank <= 20 THEN 'Top 20'
        ELSE 'Others'
    END AS RankCategory
FROM 
    RankedPosts rp
INNER JOIN 
    PostTypes pt ON rp.PostTypeId = pt.Id
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 100;
