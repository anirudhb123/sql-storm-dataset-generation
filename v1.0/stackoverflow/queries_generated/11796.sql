-- Performance Benchmarking Query

-- This query measures the performance of retrieving posts along with their associated comments, votes, and user information.
-- It includes aggregations to calculate the total number of comments and votes for each post, and filters for posts with a minimum score.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.ViewCount,
    p.Score,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COUNT(DISTINCT v.Id) AS TotalVotes
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.Score > 0 -- Filter for posts with a positive score
GROUP BY 
    p.Id, p.Title, p.ViewCount, p.Score, p.CreationDate, u.DisplayName
ORDER BY 
    p.Score DESC, p.CreationDate DESC;
