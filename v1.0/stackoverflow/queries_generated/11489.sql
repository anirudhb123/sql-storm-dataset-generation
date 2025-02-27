-- Performance Benchmarking SQL Query

-- This query retrieves aggregate information about posts, their authors, and user activity
-- to evaluate the performance of the database under a complex read operation scenario.

SELECT 
    p.Id AS PostID,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS Author,
    u.Reputation AS AuthorReputation,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'  -- Filtering to only the posts created in the last year
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC;  -- Ordering by the latest posts
