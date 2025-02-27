-- Performance Benchmarking Query Example

-- This query retrieves data from multiple tables to analyze
-- post activity and user engagement on Stack Overflow.

WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        COALESCE(Count(c.Id), 0) AS CommentCount,
        COALESCE(Count(v.Id), 0) AS VoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        u.Reputation AS UserReputation
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= '2023-01-01'  -- filter for posts created in 2023
    GROUP BY p.Id, u.Reputation
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.LastActivityDate,
    ps.ViewCount,
    ps.CommentCount,
    ps.VoteCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    ps.UserReputation
FROM PostStats ps
ORDER BY ps.ViewCount DESC -- Order by view count to find the most viewed posts
LIMIT 100; -- Limit to top 100 posts for performance benchmarking
