-- Performance benchmarking query to evaluate the activity on posts, votes, and user interactions

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    p.LastActivityDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    p.CreationDate >= '2022-01-01' -- Filter for posts created after January 1, 2022
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, u.DisplayName, u.Reputation, p.LastActivityDate
ORDER BY 
    p.ViewCount DESC; -- Ordering by view count for benchmarking popularity
