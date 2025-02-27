-- Performance benchmarking query to retrieve a summary of posts along with user details and vote counts
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    p.CommentCount,
    u.Id AS UserId,
    u.DisplayName AS UserDisplayName,
    u.Reputation AS UserReputation,
    COUNT(v.Id) AS VoteCount,
    MAX(v.CreationDate) AS LastVoteDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2023-01-01' -- Adjust date range for benchmarking
GROUP BY 
    p.Id, u.Id
ORDER BY 
    p.CreationDate DESC;
