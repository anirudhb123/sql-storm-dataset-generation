
WITH TagStatistics AS (
    SELECT 
        LOWER(TRIM(TAG)) AS NormalizedTag,
        COUNT(*) AS TagCount,
        GROUP_CONCAT(DISTINCT p.Title SEPARATOR ', ') AS PostTitles,
        SUM(CASE WHEN p.ViewCount > 1000 THEN 1 ELSE 0 END) AS HighViewCountPosts,
        AVG(p.Score) AS AverageScore,
        GROUP_CONCAT(DISTINCT u.DisplayName SEPARATOR ', ') AS TopUsers
    FROM 
        Posts p
    JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) TAG
         FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
               UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
               UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS Tags 
    ON TRUE
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        LOWER(TRIM(TAG)), p.OwnerUserId
),

TagRanked AS (
    SELECT 
        NormalizedTag,
        TagCount,
        PostTitles,
        HighViewCountPosts,
        AverageScore,
        TopUsers,
        @rank := IF(@prev_tagcount = TagCount, @rank, @rank + 1) AS TagRanking,
        @prev_tagcount := TagCount
    FROM 
        TagStatistics, (SELECT @rank := 0, @prev_tagcount := NULL) AS init
    ORDER BY 
        TagCount DESC
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
