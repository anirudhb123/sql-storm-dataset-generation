WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        t.TagName,
        ROW_NUMBER() OVER (PARTITION BY t.TagName ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    CROSS JOIN 
        UNNEST(string_to_array(p.Tags, '>')) AS tag(t.TagName)
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, t.TagName
),
PopularTags AS (
    SELECT
        t.TagName,
        COUNT(p.PostId) AS PostCount,
        SUM(p.CommentCount) AS TotalComments,
        SUM(p.AnswerCount) AS TotalAnswers
    FROM 
        RankedPosts p
    GROUP BY 
        t.TagName
)
SELECT 
    t.TagName,
    p.PostCount,
    p.TotalComments,
    p.TotalAnswers,
    RANK() OVER (ORDER BY p.PostCount DESC) AS TagPopularityRank
FROM
    PopularTags p
WHERE
    p.PostCount > 5  -- Filter for tags with more than 5 posts
ORDER BY 
    TagPopularityRank;

This query benchmarks string processing by analyzing the tags used in posts according to a specified schema. It calculates the popularity of tags based on the number of questions and their corresponding comments and answers, providing an insightful overview of trending topics within the posts.
