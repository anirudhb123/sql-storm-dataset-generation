-- Benchmarking string processing by analyzing post titles and tags
WITH TitleTagAnalysis AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        LENGTH(p.Title) AS TitleLength,
        ARRAY_LENGTH(string_to_array(substring(p.Tags, 2, LENGTH(p.Tags) - 2), '><'), 1) AS TagCount,
        ARRAY_AGG(DISTINCT tg.TagName) AS UniqueTags,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  -- Filtering for BountyStart votes
    LEFT JOIN 
        Tags tg ON tg.Id = ANY(string_to_array(substring(p.Tags, 2, LENGTH(p.Tags) - 2), '><'))::int[] 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Latest posts from the past year
    GROUP BY 
        p.Id, p.Title, p.Tags
),
Statistics AS (
    SELECT 
        AVG(TitleLength) AS AvgTitleLength,
        AVG(TagCount) AS AvgTagCount,
        COUNT(PostId) AS TotalPosts,
        SUM(CommentCount) AS TotalComments,
        SUM(TotalBounty) AS TotalBountyAwards
    FROM 
        TitleTagAnalysis
)
SELECT 
    AvgTitleLength,
    AvgTagCount,
    TotalPosts,
    TotalComments,
    TotalBountyAwards,
    CASE 
        WHEN TotalPosts > 0 THEN (TotalBountyAwards::decimal / TotalPosts) 
        ELSE 0 
    END AS AvgBountyPerPost
FROM 
    Statistics;
