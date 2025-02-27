
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankPerUser,
        COUNT(v.Id) AS VoteCount,
        STRING_AGG(DISTINCT t.TagName, ',') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  
    CROSS APPLY 
        STRING_SPLIT(p.Tags, '>') AS t
    WHERE 
        p.CreationDate >= CAST('2024-10-01' AS DATE) - 30  
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.RankPerUser,
        rp.VoteCount,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.VoteCount >= 5  
)
SELECT 
    tp.Id,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tp.Tags,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = tp.Id) AS CommentCount
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
