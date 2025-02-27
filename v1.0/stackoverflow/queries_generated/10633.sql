-- Performance benchmarking query for analyzing posts and their associated user actions
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        AVG(v.CreationDate) AS AvgVoteDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2 -- Answers related to Questions
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Filter for posts created in the last year
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.LastActivityDate, p.ViewCount, p.Score
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.LastActivityDate,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ps.AnswerCount,
    (EXTRACT(EPOCH FROM NOW()) - EXTRACT(EPOCH FROM ps.AvgVoteDate)) AS TimeSinceLastVote
FROM 
    PostStats ps
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC
LIMIT 100; -- Limit to top 100 posts by score and views
