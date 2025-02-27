-- Performance Benchmarking SQL Query

-- Measure the time taken to execute a combination of joins and aggregations
SELECT 
    p.Title AS PostTitle,
    u.DisplayName AS Author,
    COUNT(c.Id) AS CommentCount,
    SUM(v.VoteTypeId = 2) AS UpvoteCount,
    SUM(v.VoteTypeId = 3) AS DownvoteCount,
    ph.CreationDate AS LastEditDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    p.CreationDate > '2020-01-01' -- Filter to include posts created after this date
GROUP BY 
    p.Id, u.DisplayName, ph.CreationDate
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Limit to the latest 100 posts for benchmarking performance
