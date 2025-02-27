WITH TaggedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only include Questions
),
PostRecommendations AS (
    SELECT 
        tp1.PostId AS SourcePostId,
        tp2.PostId AS RelatedPostId,
        COUNT(*) AS CommonTags
    FROM 
        TaggedPosts tp1
    JOIN 
        TaggedPosts tp2 ON tp1.Tag = tp2.Tag AND tp1.PostId <> tp2.PostId
    GROUP BY 
        tp1.PostId, tp2.PostId
    HAVING 
        COUNT(*) > 1 -- Only consider posts with more than one common tag
),
MostCommonTags AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        TaggedPosts
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    p.Id,
    p.Title,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    ARRAY_AGG(DISTINCT tp.Tag) AS PostTags,
    COALESCE(r.RelatedPosts, '{}'::int[]) AS RelatedPostIds,
    mt.TagCount
FROM 
    Posts p
LEFT JOIN 
    PostRecommendations r ON r.SourcePostId = p.Id
LEFT JOIN 
    TaggedPosts tp ON tp.PostId = p.Id
LEFT JOIN 
    MostCommonTags mt ON mt.Tag = ANY(tp.Tag)
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Id
ORDER BY 
    p.ViewCount DESC
LIMIT 50;

This query performs the following operations:

1. **Extracts Tags**: The `TaggedPosts` CTE breaks down the tags from the `Posts` table for all questions.
2. **Finds Related Posts**: The `PostRecommendations` CTE identifies related posts based on shared tags, counting how many tags are shared.
3. **Most Common Tags**: The `MostCommonTags` CTE retrieves the top 10 most common tags across all questions.
4. **Final Selection**: The outer query collects details from `Posts`, including the number of views, answers, comments, and tags, linking to related posts and incorporating the most common tags where applicable. The results are sorted based on the view count.
