-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        COALESCE((SELECT COUNT(a.Id) FROM Posts a WHERE a.AcceptedAnswerId = p.Id), 0) AS AcceptedAnswers
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        unnest(string_to_array(p.Tags, '<>')) AS t(TagName) ON true
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
)

SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    CommentCount,
    VoteCount,
    Tags,
    AcceptedAnswers
FROM 
    PostStats
ORDER BY 
    Score DESC, ViewCount DESC;
