-- Performance benchmarking query: retrieve the top 10 most upvoted posts along with their authors and their vote counts

SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score AS UpvoteCount,
    u.DisplayName AS Author,
    COUNT(v.Id) AS TotalVotes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.PostTypeId IN (1, 2)  -- Consider only questions and answers
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.Score DESC
LIMIT 10;
