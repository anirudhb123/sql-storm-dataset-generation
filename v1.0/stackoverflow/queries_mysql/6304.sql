
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR
), 
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        ViewCount, 
        AnswerCount, 
        CommentCount, 
        FavoriteCount, 
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
), 
PostTags AS (
    SELECT 
        p.Id AS PostId,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) AS tag
         FROM 
             (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
              SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
              SELECT 9 UNION ALL SELECT 10) numbers 
         WHERE 
             CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag 
    ON tag <> '' 
    JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        p.Id
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.CommentCount,
    tp.FavoriteCount,
    tp.OwnerDisplayName,
    pt.Tags
FROM 
    TopPosts tp
LEFT JOIN 
    PostTags pt ON tp.PostId = pt.PostId
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
