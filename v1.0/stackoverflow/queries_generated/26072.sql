WITH TagStatistics AS (
    SELECT 
        LOWER(TAG.Trim()) AS NormalizedTag,
        COUNT(*) AS TagCount,
        STRING_AGG(DISTINCT p.Title, ', ') AS PostTitles,
        SUM(CASE WHEN p.ViewCount > 1000 THEN 1 ELSE 0 END) AS HighViewCountPosts,
        AVG(p.Score) AS AverageScore,
        ARRAY_AGG(DISTINCT u.DisplayName) AS TopUsers
    FROM 
        Posts p
    JOIN 
        UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) AS TAG ON TRUE
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Considering only Questions
    GROUP BY 
        NormalizedTag
),

TagRanked AS (
    SELECT 
        NormalizedTag,
        TagCount,
        PostTitles,
        HighViewCountPosts,
        AverageScore,
        TopUsers,
        DENSE_RANK() OVER (ORDER BY TagCount DESC) AS TagRanking
    FROM 
        TagStatistics
)

SELECT 
    *,
    CASE 
        WHEN HighViewCountPosts > 5 THEN 'Popular'
        WHEN AverageScore >= 10 THEN 'High-Scoring'
        ELSE 'Regular'
    END AS TagCategory
FROM 
    TagRanked
WHERE 
    TagCount > 10
ORDER BY 
    TagRanking;
