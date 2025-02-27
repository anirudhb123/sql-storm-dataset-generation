-- Performance benchmarking query for retrieving the most popular questions based on score, along with their authors and tags

SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    p.ViewCount,
    p.CreationDate,
    u.DisplayName AS Author,
    p.Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 -- Only questions
    AND p.Score > 0 -- Only those with a score greater than zero
ORDER BY 
    p.Score DESC, 
    p.ViewCount DESC -- Order by score then by view count
LIMIT 100; -- Limit results to top 100 popular questions
