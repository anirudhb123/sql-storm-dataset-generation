
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.PostId IN (SELECT ParentId FROM Posts WHERE Id = rp.PostId AND ParentId IS NOT NULL)
    WHERE 
        rp.rn <= 5
),
PostWithComments AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Score,
        COUNT(c.Id) AS CommentCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.Score
)
SELECT 
    pwc.PostId,
    pwc.Title,
    pwc.Score,
    pwc.CommentCount,
    CASE 
        WHEN pwc.CommentCount > 10 THEN 'Highly Discussed'
        WHEN pwc.CommentCount BETWEEN 5 AND 10 THEN 'Moderately Discussed'
        ELSE 'Less Discussed'
    END AS DiscussionLevel,
    (SELECT 
        GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') 
     FROM 
        Tags t 
     JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS tag
         FROM 
         (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
          SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
          SELECT 9 UNION ALL SELECT 10) numbers 
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1) AS tag 
     ON t.TagName = tag) AS TagsUsed
FROM 
    PostWithComments pwc
JOIN 
    Posts p ON pwc.PostId = p.Id
WHERE 
    p.ClosedDate IS NULL
ORDER BY 
    pwc.Score DESC, 
    pwc.CommentCount DESC
LIMIT 20;
