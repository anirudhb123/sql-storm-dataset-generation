
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
        array_size(split(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS TagCount,
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
        tag AS Tag
    FROM 
        RankedPosts,
        lateral flatten(input => split(substring(Tags, 2, length(Tags) - 2), '><'))
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
        TagCounts tp ON rp.Tags ILIKE '%' || tp.Tag || '%' 
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
