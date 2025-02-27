-- Performance Benchmarking Query for Stack Overflow Schema

-- This query retrieves statistics on posts, including counts of associated comments,
-- votes, and badges, to evaluate the performance at fetching related data.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    COUNT(b.Id) AS BadgeCount
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON p.OwnerUserId = b.UserId
WHERE 
    p.CreationDate >= '2022-01-01' -- Filter for posts created since 2022
GROUP BY 
    p.Id
ORDER BY 
    p.CreationDate DESC;

-- Execution plan and response time can be analyzed from this query to assess performance.
