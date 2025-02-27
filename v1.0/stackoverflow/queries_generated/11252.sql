-- Performance benchmarking query to retrieve statistics about posts, users, and votes

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.CommentCount,
    p.AnswerCount,
    u.Id AS UserId,
    u.DisplayName AS UserDisplayName,
    u.Reputation,
    v.VoteTypeId,
    COUNT(v.Id) AS VoteCount,
    AVG(DATEDIFF('second', p.CreationDate, v.CreationDate)) AS AvgTimeToVote
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year' -- Consider posts created in the last year
GROUP BY 
    p.Id, u.Id, v.VoteTypeId
ORDER BY 
    p.CreationDate DESC;
