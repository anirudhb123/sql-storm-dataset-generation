-- Performance benchmarking query to evaluate the number of posts and their respective vote counts
SELECT 
    p.Id AS PostId,
    p.Title,
    p.ViewCount,
    p.CreationDate,
    p.Score,
    COUNT(v.Id) AS VoteCount,
    COUNT(c.Id) AS CommentCount
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.CreationDate >= '2023-01-01'  -- Filter for posts created in 2023
GROUP BY 
    p.Id, p.Title, p.ViewCount, p.CreationDate, p.Score
ORDER BY 
    VoteCount DESC, p.Score DESC;  -- Order by number of votes and then by score for better insights
