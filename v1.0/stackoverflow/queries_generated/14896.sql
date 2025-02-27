-- Performance Benchmarking Query
-- This query benchmarks the performance of commonly used Join operations across multiple related tables

SELECT 
    u.DisplayName AS UserDisplayName,
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    p.ViewCount AS PostViewCount,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    COUNT(b.Id) AS BadgeCount,
    pt.Name AS PostTypeName,
    ht.Name AS PostHistoryTypeName
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
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    PostHistory h ON p.Id = h.PostId
LEFT JOIN 
    PostHistoryTypes ht ON h.PostHistoryTypeId = ht.Id
WHERE 
    p.CreationDate >= '2023-01-01' -- filter by posts created in the year 2023
GROUP BY 
    u.Id, p.Id, pt.Name, ht.Name
ORDER BY 
    PostViewCount DESC
LIMIT 100; -- Limit the results to the top 100 posts by view count
