WITH EnhancedPostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(NULLIF(p.Body, ''), 'No content') AS BodySnippet,
        pt.Name AS PostType,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag_array ON TRUE
    LEFT JOIN 
        Tags t ON tag_array.value = t.TagName
    WHERE 
        p.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '1 year')
    GROUP BY 
        p.Id, pt.Name
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        BodySnippet,
        PostType,
        CommentCount,
        VoteCount,
        Tags,
        ROW_NUMBER() OVER (ORDER BY Score DESC, ViewCount DESC) AS Rank
    FROM 
        EnhancedPostStatistics
)
SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    Score,
    BodySnippet,
    PostType,
    CommentCount,
    VoteCount,
    Tags
FROM 
    TopPosts
WHERE 
    Rank <= 10
ORDER BY 
    Score DESC, ViewCount DESC;

This SQL query aims to benchmark string processing and aggregation within the Stack Overflow schema by evaluating posts from the last year, aggregating related data, and ranking them based on scores and view counts.
