
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR
        AND p.PostTypeId IN (1, 2) 
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Score,
        rp.ViewCount,
        rp.Tags,
        rp.CreationDate,
        rp.LastActivityDate
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 10 
),
TagOccurrences AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, '>', numbers.n), '>', -1)) AS Tag
    FROM 
        TopPosts rp
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(rp.Tags) - CHAR_LENGTH(REPLACE(rp.Tags, '>', '')) >= numbers.n - 1
),
TagCounts AS (
    SELECT 
        Tag,
        COUNT(*) AS OccurrenceCount
    FROM 
        TagOccurrences
    GROUP BY 
        Tag
    ORDER BY 
        OccurrenceCount DESC
    LIMIT 5 
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.Score,
    tp.ViewCount,
    tc.Tag,
    tc.OccurrenceCount
FROM 
    TopPosts tp
JOIN 
    TagCounts tc ON tp.Tags LIKE CONCAT('%', tc.Tag, '%')
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;
