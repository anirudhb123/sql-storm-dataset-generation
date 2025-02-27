-- Performance benchmarking query
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS PostCount,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
    SUM(CASE WHEN p.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TagWikis,
    AVG(p.Score) AS AvgPostScore,
    MAX(p.ViewCount) AS MaxPostViewCount,
    AVG(COALESCE(c.CommentCount, 0)) AS AvgCommentCount,
    COUNT(DISTINCT b.Id) AS BadgeCount
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    u.Reputation > 0  -- Only consider users with a positive reputation
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    PostCount DESC, u.Reputation DESC
LIMIT 100; -- Limit to top 100 users based on post count
