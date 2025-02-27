
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
    AND 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    INNER JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL 
         SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL 
         SELECT 10) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 5
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.Score,
    rp.CreationDate,
    pt.TagName,
    pt.TagCount
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags pt ON rp.Title LIKE CONCAT('%', pt.TagName, '%')
WHERE 
    rp.Rank <= 3
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;
