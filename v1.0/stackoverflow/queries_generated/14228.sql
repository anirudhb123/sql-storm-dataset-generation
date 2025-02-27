-- Performance benchmarking query on the Stack Overflow schema

-- This query retrieves a summary of posts, their types, user reputation, and associated votes.
SELECT 
    p.Id AS PostId,
    p.Title,
    pt.Name AS PostType,
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(v.Id) AS VoteCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
    p.CreationDate,
    p.LastActivityDate,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    p.FavoriteCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts created in the last year
GROUP BY 
    p.Id, pt.Name, u.Id
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Limit to the most recent 100 posts
