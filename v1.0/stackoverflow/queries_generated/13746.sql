-- Performance benchmarking query for analyzing Posts along with their respective Users and related Votes.
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score AS PostScore,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    p.FavoriteCount,
    u.Id AS UserId,
    u.DisplayName AS UserDisplayName,
    u.Reputation AS UserReputation,
    v.VoteTypeId AS VoteType,
    COUNT(v.Id) AS VoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2020-01-01' -- Filter for posts created from January 1, 2020
GROUP BY 
    p.Id, u.Id, v.VoteTypeId
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Limit to the 100 most recent posts
