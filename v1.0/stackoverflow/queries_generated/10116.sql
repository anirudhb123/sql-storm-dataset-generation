-- This SQL query is designed for performance benchmarking, focusing on the most frequently interacted posts,
-- their associated users, and the comments on those posts.

WITH PostInteraction AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVoteCount, -- UpVotes
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVoteCount -- DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month' -- Adjust the interval as needed
    GROUP BY 
        p.Id
)

SELECT 
    pi.PostId,
    pi.Title,
    pi.CreationDate,
    pi.ViewCount,
    pi.Score,
    pi.CommentCount,
    pi.UpVoteCount,
    pi.DownVoteCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation
FROM 
    PostInteraction pi
JOIN 
    Users u ON pi.PostId = u.AccountId
ORDER BY 
    pi.Score DESC, pi.ViewCount DESC
LIMIT 100; -- Adjust the limit as needed for benchmarking
