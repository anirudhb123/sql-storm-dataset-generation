-- Performance Benchmarking Query

-- This query measures the average time taken to retrieve the most recent posts along with their author and associated comments.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    u.DisplayName AS AuthorDisplayName,
    COUNT(c.Id) AS CommentCount,
    AVG(DATEDIFF(SECOND, p.CreationDate, c.CreationDate)) AS AvgCommentTime
FROM 
    Posts p
INNER JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.CreationDate >= '2023-01-01' -- Filtering posts created in the year 2023
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Limit to the most recent 100 posts
