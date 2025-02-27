WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        ARRAY_LENGTH(string_to_array(p.Tags, '><'), 1) AS TagCount,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId = 1  -- Only Questions
)
SELECT 
    f.PostId,
    f.Title,
    f.TagCount,
    f.ViewCount,
    f.AnswerCount,
    f.CommentCount,
    f.Score,
    f.OwnerDisplayName,
    f.OwnerReputation,
    string_agg(DISTINCT t.TagName, ', ') AS Tags,
    COALESCE(MAX(CASE WHEN b.Class = 1 THEN b.Name END), '') AS GoldBadge,
    COALESCE(MAX(CASE WHEN b.Class = 2 THEN b.Name END), '') AS SilverBadge,
    COALESCE(MAX(CASE WHEN b.Class = 3 THEN b.Name END), '') AS BronzeBadge
FROM 
    FilteredPosts f
LEFT JOIN 
    PostTags pt ON pt.PostId = f.PostId
LEFT JOIN 
    Tags t ON t.Id = pt.TagId
LEFT JOIN 
    Badges b ON b.UserId = f.OwnerUserId
GROUP BY 
    f.PostId, f.Title, f.TagCount, f.ViewCount, f.AnswerCount, f.CommentCount, f.Score, f.OwnerDisplayName, f.OwnerReputation
ORDER BY 
    f.ViewCount DESC, 
    f.AnswerCount DESC, 
    f.Score DESC
LIMIT 100;
This query benchmarks string processing by utilizing various string manipulation functions, filtering, and aggregating data on posts from the past year while providing insights into user engagement metrics and tag usage. The result set includes enriched information by linking badges to the post owners, showcasing the intersection of community engagement with post performance.
