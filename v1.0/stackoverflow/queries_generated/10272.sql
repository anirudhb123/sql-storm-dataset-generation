-- Performance Benchmarking Query for StackOverflow Schema
-- This query aims to analyze the relationships and activity in the Posts, Users, and Votes tables

WITH PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        u.Reputation AS OwnerReputation,
        COUNT(v.Id) AS VoteCount,
        AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        AVG(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- focusing on posts created in the last year
    GROUP BY 
        p.Id, u.Reputation
)

SELECT 
    pa.PostId,
    pa.Title,
    pa.ViewCount,
    pa.Score,
    pa.AnswerCount,
    pa.CommentCount,
    pa.OwnerReputation,
    pa.VoteCount,
    pa.UpVotes,
    pa.DownVotes
FROM 
    PostActivity pa
ORDER BY 
    pa.Score DESC, pa.ViewCount DESC; -- prioritize posts by score and view count
