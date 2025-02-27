-- Performance Benchmarking SQL Query

-- This query retrieves the most voted posts along with their user details
-- and the number of comments to assess overall engagement.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score AS PostScore,
    u.DisplayName AS AuthorDisplayName,
    u.Reputation AS AuthorReputation,
    c.CommentCount,
    COUNT(v.Id) AS VoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.PostTypeId = 1  -- Selecting only questions
GROUP BY 
    p.Id, u.DisplayName, u.Reputation, p.Title, p.CreationDate, p.Score, c.CommentCount
ORDER BY 
    VoteCount DESC, PostScore DESC
LIMIT 100; -- Limiting to top 100 posts based on votes and score
