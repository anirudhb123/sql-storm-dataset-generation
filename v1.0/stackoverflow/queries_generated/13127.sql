-- Performance Benchmarking Query for Stack Overflow Schema
-- This query retrieves statistics about posts, including vote counts and comment counts
-- It will help evaluate performance by analyzing response time and resource usage

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'  -- Adjust time frame as needed
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount
ORDER BY 
    p.ViewCount DESC  -- Orders by most viewed posts
LIMIT 100;  -- Limit the output for performance testing
