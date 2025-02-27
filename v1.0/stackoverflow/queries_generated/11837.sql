-- Performance benchmarking query to analyze post activity and user interactions

WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 6 THEN 1 ELSE 0 END), 0) AS CloseVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 7 THEN 1 ELSE 0 END), 0) AS ReopenVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Benchmarking for the last year
    GROUP BY 
        p.Id
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.AnswerCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.CloseVotes,
    ps.ReopenVotes
FROM 
    PostStatistics ps
ORDER BY 
    ps.ViewCount DESC, ps.Score DESC;  -- Ordering by Views and Score for performance analysis
