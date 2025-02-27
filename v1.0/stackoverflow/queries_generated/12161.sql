-- Performance benchmarking query to analyze posts and their interactions
SELECT 
    p.Id AS PostID,
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    p.ViewCount AS Views,
    COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
    COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT ph.Id) AS EditCount,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostsCount
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    Badges b ON p.OwnerUserId = b.UserId
LEFT JOIN 
    PostLinks pl ON p.Id = pl.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year' -- Consider only posts created in the last year
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount
ORDER BY 
    Views DESC; -- Order by views to benchmark the most interacted posts
