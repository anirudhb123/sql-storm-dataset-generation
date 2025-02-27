
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        p.Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
FilteredTags AS (
    SELECT 
        pt.TagName,
        COUNT(pt.TagName) AS TagCount
    FROM 
        Posts p
    JOIN 
        (SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
         FROM 
            Posts p
         JOIN 
            (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL
             SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL
             SELECT 9 UNION ALL SELECT 10) numbers 
         ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS pt 
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01 12:34:56', INTERVAL 1 YEAR)
    GROUP BY 
        pt.TagName
    HAVING 
        COUNT(pt.TagName) > 5
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.CreationDate AS PostCreationDate,
    rp.OwnerDisplayName,
    ft.TagName,
    ft.TagCount
FROM 
    RankedPosts rp
JOIN 
    FilteredTags ft ON FIND_IN_SET(ft.TagName, SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, '><', numbers.n), '><', -1))
WHERE 
    rp.Rank = 1
ORDER BY 
    rp.ViewCount DESC, 
    ft.TagCount DESC
LIMIT 10;
