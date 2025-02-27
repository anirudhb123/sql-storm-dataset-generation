-- Performance benchmarking query for Stack Overflow schema
WITH PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(MAX(v.BountyAmount), 0) AS MaxBountyAmount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1  -- Answers linked to Questions
    LEFT JOIN 
        Comments c ON p.Id = c.PostId  -- Comments for each Post
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId  -- Post links to related Posts
    LEFT JOIN 
        PostTags pt ON p.Id = pt.PostId  -- Tags association
    LEFT JOIN 
        Tags t ON pt.TagId = t.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Last year's posts
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
)

SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    AnswerCount,
    CommentCount,
    MaxBountyAmount,
    Tags
FROM 
    PostSummary
ORDER BY 
    ViewCount DESC, Score DESC
LIMIT 100;  -- Top 100 posts by ViewCount and Score
