-- Performance Benchmarking Query
-- This query retrieves the latest posts along with their types, the number of associated comments, votes, and badges for the users who created them.

SELECT 
    p.Id AS PostId,
    p.Title,
    pt.Name AS PostType,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    u.Reputation AS UserReputation,
    u.DisplayName AS UserDisplayName,
    COUNT(b.Id) AS BadgeCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    p.CreationDate >= DATEADD(MONTH, -1, GETDATE()) -- Filtering for posts created in the last month
GROUP BY 
    p.Id, p.Title, pt.Name, u.Id
ORDER BY 
    p.CreationDate DESC; -- Order by the most recent posts
