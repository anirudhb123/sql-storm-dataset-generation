-- Performance benchmarking query to analyze posts creation and user engagement statistics

WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,  -- Counting UpVotes
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes  -- Counting DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS AnswerCount 
         FROM Posts 
         WHERE PostTypeId = 2 
         GROUP BY PostId) a ON p.Id = a.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount 
         FROM Comments 
         GROUP BY PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Filtering for the last year
    GROUP BY 
        p.Id, a.AnswerCount, c.CommentCount
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.AnswerCount,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    (ps.UpVotes - ps.DownVotes) AS NetVotes,
    (ps.ViewCount / NULLIF(ps.AnswerCount, 0)) AS ViewsPerAnswer,  -- Views per answer
    (ps.ViewCount / NULLIF(ps.CommentCount, 0)) AS ViewsPerComment   -- Views per comment
FROM 
    PostStats ps
ORDER BY 
    ps.ViewCount DESC  -- Order by most viewed posts
LIMIT 100;  -- Limit results to the top 100 posts
