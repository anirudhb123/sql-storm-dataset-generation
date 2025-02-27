-- Performance Benchmarking SQL Query
-- This query retrieves a summary of posts, including the number of answers, views, and votes, to analyze performance metrics.

SELECT 
    p.Id AS PostID,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.AnswerCount,
    COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
    COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    u.Reputation AS OwnerReputation
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    p.CreationDate >= '2023-01-01'  -- Filtering posts created this year
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, p.AnswerCount, u.Reputation
ORDER BY 
    p.ViewCount DESC  -- Sorting by views for performance analysis
LIMIT 100;  -- Limiting to the top 100 posts for benchmarking
