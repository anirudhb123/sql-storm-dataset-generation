-- Performance benchmarking query to analyze Posts and their associated data, including User information and PostHistory
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    u.Id AS UserId,
    u.DisplayName AS UserDisplayName,
    u.Reputation,
    COUNT(v.Id) AS TotalVotes,
    MAX(ph.CreationDate) AS LastEditDate,
    STRING_AGG(DISTINCT ph.Comment, '; ') AS PostHistoryComments
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'  -- Filter for posts created in the last year
GROUP BY 
    p.Id, u.Id
ORDER BY 
    p.CreationDate DESC;
