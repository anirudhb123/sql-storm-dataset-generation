-- Performance benchmarking query to analyze post data and user engagement
  
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    p.CommentCount,
    p.FavoriteCount,
    u.Reputation AS OwnerReputation,
    u.DisplayName AS OwnerDisplayName,
    COUNT(DISTINCT c.Id) AS TotalComments,
    AVG(vote.Score) AS AverageVoteScore,
    AVG(DATEDIFF(MINUTE, p.CreationDate, v.CreationDate)) AS AvgTimeToFirstVote
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON c.PostId = p.Id
LEFT JOIN 
    Votes vote ON vote.PostId = p.Id
WHERE 
    p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Only consider posts from the last year
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.AnswerCount, p.CommentCount, p.FavoriteCount, u.Reputation, u.DisplayName
ORDER BY 
    p.Score DESC, p.ViewCount DESC;
