WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.Tags,
        RANK() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Questions from the last year
        AND p.Score > 0 -- Only questions with a score greater than 0
), FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5 -- Get top 5 ranked posts per tag
)

SELECT 
    f.PostId,
    f.Title,
    f.OwnerDisplayName,
    f.ViewCount,
    f.Score,
    f.AnswerCount,
    STRING_AGG(t.TagName, ', ') AS RelatedTags,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT ph.Id) AS EditCount,
    SUM(v.VoteTypeId = 2) AS TotalUpvotes, -- Upvotes
    SUM(v.VoteTypeId = 3) AS TotalDownvotes -- Downvotes
FROM 
    FilteredPosts f
LEFT JOIN 
    Comments c ON f.PostId = c.PostId
LEFT JOIN 
    PostHistory ph ON f.PostId = ph.PostId
LEFT JOIN 
    STRING_TO_ARRAY(f.Tags, ',') AS tag_array ON TRUE
LEFT JOIN 
    Tags t ON TRIM(tag_array) = t.TagName
LEFT JOIN 
    Votes v ON f.PostId = v.PostId
GROUP BY 
    f.PostId, f.Title, f.OwnerDisplayName, f.ViewCount, f.Score, f.AnswerCount
ORDER BY 
    f.Score DESC, f.ViewCount DESC;
