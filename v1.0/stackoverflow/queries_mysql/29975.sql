
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PopularTags AS (
    SELECT 
        LOWER(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1))) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    INNER JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1 
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    trp.Title,
    trp.ViewCount,
    trp.Score,
    GROUP_CONCAT(DISTINCT pt.Name) AS PostTypes,
    GROUP_CONCAT(DISTINCT pgt.Tag) AS PopularTags
FROM 
    TopRankedPosts trp
LEFT JOIN 
    PostTypes pt ON trp.PostId IN (SELECT p.Id FROM Posts p WHERE p.PostTypeId = pt.Id)
LEFT JOIN 
    PopularTags pgt ON FIND_IN_SET(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(trp.Tags, '><', numbers.n), '><', -1)), pgt.Tag)
GROUP BY 
    trp.PostId, trp.Title, trp.ViewCount, trp.Score
ORDER BY 
    trp.Score DESC, trp.ViewCount DESC;
