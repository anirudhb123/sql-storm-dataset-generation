
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        @row_number:=CASE WHEN @prev_user_id = p.OwnerUserId THEN @row_number + 1 ELSE 1 END AS RankPerUser,
        @prev_user_id:=p.OwnerUserId,
        COUNT(v.Id) AS VoteCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  
    LEFT JOIN 
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', n.n), '>', -1)) AS TagName
         FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
               UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 
               UNION ALL SELECT 10) n) t ON true
    CROSS JOIN (SELECT @row_number := 0, @prev_user_id := NULL) r
    WHERE 
        p.CreationDate >= CURDATE() - INTERVAL 30 DAY 
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
LIMIT 10;
