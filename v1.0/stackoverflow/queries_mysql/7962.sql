
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR) 
        AND p.Score > 0
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts p
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR) 
    GROUP BY 
        Tag
    ORDER BY 
        PostCount DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.OwnerDisplayName,
    pt.Tag,
    pt.PostCount
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON pt.PostCount > 5
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
