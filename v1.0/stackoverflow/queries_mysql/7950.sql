
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '<>', numbers.n), '<>', -1) AS tag
         FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
               SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
               SELECT 9 UNION ALL SELECT 10) numbers 
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '<>', '')) >= numbers.n - 1) AS tag ON TRUE
    JOIN 
        Tags t ON t.TagName = tag.tag
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.Score, p.ViewCount
),
PostStatistics AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        OwnerDisplayName,
        Score,
        ViewCount,
        CommentCount,
        Tags,
        @rank := @rank + 1 AS Rank
    FROM 
        RankedPosts, (SELECT @rank := 0) r
    ORDER BY 
        Score DESC, ViewCount DESC
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.OwnerDisplayName,
    p.Score,
    p.ViewCount,
    p.CommentCount,
    p.Tags,
    CASE 
        WHEN p.Rank <= 10 THEN 'Top 10'
        WHEN p.Rank <= 50 THEN 'Top 50'
        ELSE 'Others'
    END AS RankCategory
FROM 
    PostStatistics p
ORDER BY 
    p.Rank
LIMIT 100;
