
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        p.Tags,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0 
        AND p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR
),
TagPopularity AS (
    SELECT
        SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><', n.n), '><', -1) AS Tag
    FROM 
        Posts
    INNER JOIN 
        (SELECT 1 as n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n
    ON 
        CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE 
        PostTypeId = 1
        AND Tags IS NOT NULL
),
PopularTags AS (
    SELECT 
        Tag,
        COUNT(*) AS TagFrequency
    FROM 
        TagPopularity
    GROUP BY 
        Tag
    ORDER BY 
        TagFrequency DESC
    LIMIT 10
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.ViewCount,
        rp.Score,
        rp.Tags
    FROM 
        RankedPosts rp
    JOIN 
        PopularTags pt ON rp.Tags LIKE CONCAT('%', pt.Tag, '%')
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.OwnerDisplayName,
    pp.ViewCount,
    pp.Score,
    pt.Tag
FROM 
    PopularPosts pp
CROSS JOIN 
    PopularTags pt
ORDER BY 
    pt.Tag, pp.Score DESC;
