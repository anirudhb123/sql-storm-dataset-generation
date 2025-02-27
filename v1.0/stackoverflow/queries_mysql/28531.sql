
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Author,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
)
, PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        RankedPosts
    INNER JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, ',', '')) >= numbers.n - 1
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 5 
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Author,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    pt.TagName,
    pt.TagCount
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON FIND_IN_SET(pt.TagName, rp.Tags) > 0
WHERE 
    rp.PostRank = 1 
ORDER BY 
    rp.CreationDate DESC, 
    pt.TagCount DESC
LIMIT 10;
