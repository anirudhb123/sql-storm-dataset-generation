
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '<>', n.n), '<>', -1) AS Tag
         FROM 
            (SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL 
             SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n) AS tag 
    ON tag.Tag IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag.Tag
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        CommentCount,
        Tags
    FROM 
        RankedPosts
    WHERE 
        ScoreRank <= 5
)
SELECT 
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    (SELECT COUNT(DISTINCT b.UserId) 
     FROM Badges b 
     WHERE b.UserId IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE Id = tp.PostId)) AS BadgeCount
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
