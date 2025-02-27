WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only include questions
        AND p.Score >= 0 -- Only include non-negative scored posts
),

TagAnalytics AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tag
),

HighViewPost AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        ta.Tag,
        RANK() OVER (ORDER BY rp.ViewCount DESC) AS ViewRank
    FROM 
        RankedPosts rp 
    JOIN 
        TagAnalytics ta ON ta.Tag = ANY (string_to_array(substring(rp.Tags, 2, length(rp.Tags) - 2), '><'))
    WHERE 
        rp.PostRank = 1 -- Top post for each user
)

SELECT 
    hvp.PostId,
    hvp.Title,
    hvp.CreationDate,
    hvp.ViewCount,
    hvp.Score,
    hvp.OwnerDisplayName,
    hvp.Tag
FROM 
    HighViewPost hvp
WHERE 
    hvp.ViewRank <= 10 -- Top 10 posts by view count
ORDER BY 
    hvp.ViewCount DESC;

This query performs the following steps:

1. **RankedPosts**: It ranks all questions based on their score for each user.
2. **TagAnalytics**: This CTE analyzes tags used in questions, counting how many times each tag is used.
3. **HighViewPost**: Combines the ranked posts with the tag analytics, focusing on the highest view count posts.
4. Finally, it selects details of the top 10 most viewed posts that are the top questions for each user, displaying relevant information such as title, creator, and associated tags.
