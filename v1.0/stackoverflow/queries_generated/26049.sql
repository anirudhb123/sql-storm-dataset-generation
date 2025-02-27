WITH TagUsage AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only questions
),
TagStatistics AS (
    SELECT 
        Tag, 
        COUNT(*) AS UsageCount,
        AVG(Score) AS AverageScore,
        COUNT(DISTINCT OwnerUserId) AS UniqueUserCount
    FROM 
        TagUsage 
        JOIN Posts ON Posts.Tags LIKE '%' || Tag || '%'
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag, 
        UsageCount, 
        AverageScore, 
        UniqueUserCount,
        RANK() OVER (ORDER BY UsageCount DESC) AS UsageRank,
        RANK() OVER (ORDER BY AverageScore DESC) AS ScoreRank
    FROM 
        TagStatistics
),
TagOverview AS (
    SELECT 
        Tag,
        UsageCount,
        AverageScore,
        UniqueUserCount,
        CASE 
            WHEN UsageRank <= 5 THEN 'Top Used'
            WHEN ScoreRank <= 5 THEN 'Top Scored'
            ELSE 'Regular'
        END AS TagCategory
    FROM 
        TopTags
)
SELECT 
    TagCategory,
    COUNT(Tag) AS TagCount,
    SUM(UsageCount) AS TotalUsage,
    AVG(AverageScore) AS AvgScore,
    SUM(UniqueUserCount) AS TotalUniqueUsers
FROM 
    TagOverview
GROUP BY 
    TagCategory
ORDER BY 
    TagCategory;
