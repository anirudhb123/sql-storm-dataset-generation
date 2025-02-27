
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT DISTINCT p.Id, SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
         FROM 
             (SELECT @row := @row + 1 AS n
              FROM (SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) t1,
                   (SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) t2,
                   (SELECT @row := 0) t3
             ) numbers 
         JOIN Posts p ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS t ON TRUE
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR AND p.ViewCount > 100
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, u.DisplayName, p.Score, p.ViewCount, p.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId, Title, OwnerDisplayName, Score, ViewCount, CommentCount, Tags
    FROM 
        RankedPosts
    WHERE 
        ScoreRank <= 10
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.Tags AS TagsList
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
