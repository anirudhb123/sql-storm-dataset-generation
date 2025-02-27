WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1   -- Only include Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'  -- Posts from the last year
),
FilteredPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5  -- Top 5 questions per tag
),
PostsWithComments AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.Body,
        fp.Tags,
        fp.CreationDate,
        fp.OwnerDisplayName,
        fp.Score,
        COUNT(c.Id) AS CommentCount
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        Comments c ON fp.PostId = c.PostId
    GROUP BY 
        fp.PostId, fp.Title, fp.Body, fp.Tags, fp.CreationDate, fp.OwnerDisplayName, fp.Score
),
TopPosts AS (
    SELECT 
        pwc.*,
        RANK() OVER (ORDER BY pwc.Score DESC) AS PopularityRank
    FROM 
        PostsWithComments pwc
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.Score,
    tp.CommentCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS RelatedTags
FROM 
    TopPosts tp
LEFT JOIN 
    Posts post ON tp.PostId = post.Id
LEFT JOIN 
    UNNEST(string_to_array(post.Tags, '><')) AS tag_name ON tag_name IS NOT NULL
LEFT JOIN 
    Tags t ON t.TagName = tag_name
WHERE 
    tp.PopularityRank <= 10  -- Top 10 most popular questions
GROUP BY 
    tp.PostId, tp.Title, tp.Body, tp.CreationDate, tp.OwnerDisplayName, tp.Score, tp.CommentCount
ORDER BY 
    tp.Score DESC;
