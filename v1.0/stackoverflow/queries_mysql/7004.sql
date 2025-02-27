
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        rp.CommentCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByScore <= 5
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.AnswerCount,
    tp.CommentCount,
    tp.OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    GROUP_CONCAT(DISTINCT t.TagName) AS Tags
FROM 
    TopPosts tp
LEFT JOIN 
    Comments c ON tp.PostId = c.PostId
LEFT JOIN 
    (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(tp.Title, ' ', n.n), ' ', -1)) AS tag
     FROM TopPosts tp
     JOIN (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 
           UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n
     WHERE CHAR_LENGTH(tp.Title) - CHAR_LENGTH(REPLACE(tp.Title, ' ', '')) >= n.n - 1) AS tag 
ON tag.tag IS NOT NULL
LEFT JOIN 
    Tags t ON t.TagName = tag.tag
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.ViewCount, tp.Score, tp.AnswerCount, tp.CommentCount, tp.OwnerDisplayName
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
