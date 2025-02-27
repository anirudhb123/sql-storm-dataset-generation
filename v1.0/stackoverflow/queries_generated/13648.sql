-- Performance Benchmarking Query
-- This query aims to analyze the performance of posts based on user activity and vote counts.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    p.FavoriteCount,
    u.Reputation AS UserReputation,
    u.DisplayName AS UserDisplayName,
    COUNT(v.Id) AS VoteCount,
    AVG(v.BountyAmount) AS AverageBounty
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2022-01-01'  -- Filter for posts created in 2022 and later
GROUP BY 
    p.Id, u.Id
ORDER BY 
    p.Score DESC, VoteCount DESC, p.CreationDate DESC
LIMIT 100; -- Limit the results for performance benchmarking
