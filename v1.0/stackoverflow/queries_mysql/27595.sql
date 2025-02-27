
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 1 YEAR)
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName
    FROM 
        Posts
    JOIN 
        (SELECT 1 as n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1 
),
TagPopularity AS (
    SELECT 
        TagName,
        COUNT(*) AS TagCount
    FROM 
        PopularTags
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.Score,
    rp.ViewCount,
    tp.TagName,
    tp.TagCount
FROM 
    RankedPosts rp
JOIN 
    TagPopularity tp ON FIND_IN_SET(tp.TagName, SUBSTRING(REPLACE(SUBSTRING(rp.Tags, 2, LENGTH(rp.Tags)-2), '><', ','), 1, LENGTH(SUBSTRING(rp.Tags, 2, LENGTH(rp.Tags)-2))-2))
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
