
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
        (LEN(REPLACE(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><', ''))) - 
         LEN(REPLACE(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '>', ''))) + 1) AS TagCount,
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
        value AS Tag
    FROM 
        RankedPosts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
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
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
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
        TagCounts tp ON rp.Tags LIKE '%' + tp.Tag + '%' 
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
