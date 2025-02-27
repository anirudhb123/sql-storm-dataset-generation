
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Author,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        (LENGTH(TRIM(BOTH '><' FROM p.Tags)) - LENGTH(REPLACE(TRIM(BOTH '><' FROM p.Tags), '><', ''))) + 1) AS TagCount,
        RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
PopularTags AS (
    SELECT 
        TRIM(BOTH '><' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1)) AS Tag
    FROM 
        RankedPosts
    INNER JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
),
TagCounts AS (
    SELECT 
        Tag,
        COUNT(*) AS UsageCount
    FROM 
        PopularTags
    GROUP BY 
        Tag
    ORDER BY 
        UsageCount DESC
    LIMIT 10
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Author,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        COALESCE(tp.UsageCount, 0) AS TagPopularity
    FROM 
        RankedPosts rp
    LEFT JOIN 
        TagCounts tp ON rp.Tags LIKE CONCAT('%', tp.Tag, '%') 
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Author,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.TagPopularity,
    CASE 
        WHEN ps.Score > 100 THEN 'High' 
        WHEN ps.Score BETWEEN 50 AND 100 THEN 'Medium' 
        ELSE 'Low' 
    END AS ScoreCategory
FROM 
    PostStatistics ps
WHERE 
    ps.TagPopularity > 0 
ORDER BY 
    ps.TagPopularity DESC, ps.Score DESC;
