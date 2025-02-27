WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Considering only Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'  -- Only the last year
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(Tags, '><')) AS Tag
    FROM 
        RankedPosts
    WHERE 
        TagRank <= 3  -- Get top 3 recent questions per tag
),
TagPopularity AS (
    SELECT 
        Tag, COUNT(*) AS TagCount
    FROM 
        PopularTags
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 10  -- Top 10 tags based on post popularity
)
SELECT 
    t.Tag,
    tp.TagCount,
    COUNT(DISTINCT p.Id) AS QuestionCount,
    COALESCE(SUM(c.Score), 0) AS TotalComments,
    COALESCE(SUM(v.VoteTypeId = 2::smallint), 0) AS TotalUpVotes
FROM 
    TagPopularity tp
JOIN 
    Posts p ON p.Tags LIKE '%' || tp.Tag || '%'  -- Ensuring the tag is in the post's tags
LEFT JOIN 
    Comments c ON c.PostId = p.Id
LEFT JOIN 
    Votes v ON v.PostId = p.Id
WHERE 
    p.PostTypeId = 1  -- Only questions
    AND p.CreationDate >= NOW() - INTERVAL '1 year'  -- Only the last year
GROUP BY 
    t.Tag, tp.TagCount
ORDER BY 
    tp.TagCount DESC;

This SQL query evaluates the popularity of specific tags over a period of one year by analyzing recent questions, counting comments and upvotes for related posts, and showcasing the most frequently discussed tags based on the number of questions created.
