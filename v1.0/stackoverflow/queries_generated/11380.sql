-- Performance benchmarking query to analyze post statistics, votes, and user reputation

WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COALESCE(u.Reputation, 0) AS OwnerReputation,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' -- Filter for posts created in 2023
    GROUP BY 
        p.Id, u.Reputation
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.OwnerReputation,
    ps.VoteCount,
    ps.UpVotes,
    ps.DownVotes,
    (ps.UpVotes - ps.DownVotes) AS NetVotes
FROM 
    PostStats ps
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC -- Order by score and view count for prioritization
LIMIT 100; -- Limit to top 100 posts
