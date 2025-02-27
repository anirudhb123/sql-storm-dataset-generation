-- Performance Benchmarking Query for StackOverflow Schema

-- This query provides a comprehensive overview of posts, users, and their interactions.
-- It includes details about posts, the number of answers, comments, views, votes,
-- and the reputation of the user who created the post.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    p.Score,
    u.Id AS UserId,
    u.DisplayName AS UserDisplayName,
    u.Reputation,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    MAX(v.CreationDate) AS LastVoteDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= DATEADD(year, -1, GETDATE())  -- filter for posts created in the last year
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, p.AnswerCount, p.CommentCount, p.Score, u.Id, u.DisplayName, u.Reputation
ORDER BY 
    p.Score DESC;  -- order by score to highlight popular posts
