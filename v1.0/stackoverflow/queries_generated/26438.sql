WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.ViewCount DESC) AS Rank,
        -- Extracting tags as an array for further string processing
        string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><') AS TagArray
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        pt.Name IN ('Question', 'Answer')  -- Only considering Questions and Answers
        AND p.CreationDate >= NOW() - INTERVAL '1 year'  -- Filter to the last year
),

TagStatistics AS (
    SELECT 
        unnest(RankedPosts.TagArray) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        RankedPosts
    GROUP BY 
        Tag
),

TopTags AS (
    SELECT 
        Tag,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM 
        TagStatistics
    WHERE 
        Tag IS NOT NULL
)

SELECT 
    pt.Name AS PostType,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.OwnerDisplayName,
    rp.OwnerReputation,
    tt.Tag,
    tt.TagCount
FROM 
    RankedPosts rp
JOIN 
    TopTags tt ON tt.Tag = ANY(rp.TagArray)
JOIN 
    PostTypes pt ON rp.PostTypeId = pt.Id
WHERE 
    rp.Rank <= 5 -- Limit to top 5 ranked posts per type
ORDER BY 
    pt.Name, rp.ViewCount DESC, rp.CreationDate DESC;
