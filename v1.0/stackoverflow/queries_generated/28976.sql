WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankByScore,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.ViewCount DESC) AS RankByViews,
        ARRAY_LENGTH(string_to_array(p.Tags, '>'), 1) AS TagCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 Year'
)

SELECT 
    pt.Name AS PostType,
    COUNT(rp.PostId) AS TotalPosts,
    AVG(rp.ViewCount) AS AvgViewCount,
    AVG(rp.Score) AS AvgScore,
    SUM(rp.TagCount) AS TotalTags,
    STRING_AGG(rp.Title, '; ') AS Titles,
    MAX(rp.CreationDate) AS MostRecentPostDate
FROM 
    RankedPosts rp
JOIN 
    PostTypes pt ON rp.PostId = pt.Id
WHERE 
    rp.RankByScore <= 5 OR rp.RankByViews <= 5
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC, AvgScore DESC;

This SQL query benchmarks string processing by analyzing posts created within the last year based on various metrics such as score and view count. It ranks posts within each post type by score and view count, calculates averages, and aggregates data about post titles while considering their tags. The output consists of summarized information for each post type, ordered by the total number of posts and then by average score.
