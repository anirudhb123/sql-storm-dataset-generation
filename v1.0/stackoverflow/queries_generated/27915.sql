WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND p.Score > 0 -- Only posts with a positive score
),
TopTags AS (
    SELECT
        unnest(string_to_array(Tags, ',')) AS Tag
    FROM 
        RankedPosts
)
SELECT 
    tt.Tag,
    COUNT(rp.PostId) AS PostCount,
    AVG(rp.Score) AS AvgScore,
    SUM(rp.ViewCount) AS TotalViews,
    MAX(rp.CreationDate) AS MostRecentPost
FROM 
    TopTags tt
JOIN 
    RankedPosts rp ON rp.Tags LIKE '%' || tt.Tag || '%'
GROUP BY 
    tt.Tag
ORDER BY 
    PostCount DESC, AvgScore DESC
LIMIT 10; -- Limit to the top 10 tags
