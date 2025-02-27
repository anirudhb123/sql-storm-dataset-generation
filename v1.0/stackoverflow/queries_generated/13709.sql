-- Performance Benchmarking Query
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        upVotes = COALESCE(v.UpVotes, 0),
        downVotes = COALESCE(v.DownVotes, 0),
        c.CommentCount,
        tags.Tags,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
         FROM 
            Votes
         GROUP BY 
            PostId) v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
         FROM 
            Comments 
         GROUP BY 
            PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT 
            PostId,
            STRING_AGG(TagName, ', ') AS Tags
         FROM 
            Tags t
         JOIN 
            (SELECT PostId, Tags FROM Posts) pTags ON t.Id = pTags.TAGS
         GROUP BY 
            PostId) tags ON p.Id = tags.PostId
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    AnswerCount,
    UpVotes,
    DownVotes,
    CommentCount,
    Tags,
    OwnerDisplayName
FROM 
    PostDetails
ORDER BY 
    CreationDate DESC
LIMIT 100;  -- adjust this limit for performance testing as needed
