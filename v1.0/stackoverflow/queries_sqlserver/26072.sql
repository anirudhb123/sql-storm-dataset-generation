
WITH TagStatistics AS (
    SELECT 
        LOWER(TRIM(TAG)) AS NormalizedTag,
        COUNT(*) AS TagCount,
        STRING_AGG(DISTINCT p.Title, ', ') AS PostTitles,
        SUM(CASE WHEN p.ViewCount > 1000 THEN 1 ELSE 0 END) AS HighViewCountPosts,
        AVG(p.Score) AS AverageScore,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS TopUsers
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '>') AS TAG
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        LOWER(TRIM(TAG)), 
        p.ViewCount, 
        p.Score
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
    NormalizedTag,
    TagCount,
    PostTitles,
    HighViewCountPosts,
    AverageScore,
    TopUsers,
    TagRanking,
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
