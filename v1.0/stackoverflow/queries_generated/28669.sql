WITH PostWithTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
FilteredPosts AS (
    SELECT 
        pwt.PostId,
        pwt.Title,
        pwt.Body,
        pwt.CreationDate,
        pwt.ViewCount,
        pwt.AnswerCount,
        pwt.CommentCount,
        COUNT(*) OVER(PARTITION BY pwt.Tag) AS TagCount -- Count of posts with the same tag
    FROM 
        PostWithTags pwt
    WHERE 
        pwt.ViewCount > 100 -- Only consider posts with more than 100 views
),
RankedPosts AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.Body,
        fp.CreationDate,
        fp.ViewCount,
        fp.AnswerCount,
        fp.CommentCount,
        fp.TagCount,
        ROW_NUMBER() OVER(ORDER BY fp.TagCount DESC, fp.ViewCount DESC) AS Rank
    FROM 
        FilteredPosts fp
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.TagCount,
    rp.Rank,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.PostId = u.Id
WHERE 
    rp.Rank <= 10 -- Get top 10 ranked posts
ORDER BY 
    rp.Rank;
