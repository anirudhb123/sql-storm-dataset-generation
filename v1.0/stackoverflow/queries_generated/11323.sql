-- Performance benchmarking query to retrieve key metrics from the Stack Overflow schema

SELECT 
    p.Id AS PostID,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    p.FavoriteCount,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCountTotal,
    SUM(v.BountyAmount) AS TotalBountyAmount,
    ARRAY_AGG(DISTINCT tg.TagName) AS Tags
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Tags tg ON tg.Id = ANY(string_to_array(p.Tags, ',')::int[])
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year' -- Filter for posts created in the last year
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC;
