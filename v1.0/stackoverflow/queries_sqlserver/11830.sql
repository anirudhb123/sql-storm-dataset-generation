
SELECT 
    u.DisplayName AS UserName,
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
    COALESCE(SUM(b.Class), 0) AS TotalBadges,
    AVG(DATEDIFF(SECOND, p.CreationDate, c.CreationDate)) AS AvgTimeToFirstComment
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
GROUP BY 
    u.DisplayName, p.Title, p.CreationDate
ORDER BY 
    p.CreationDate DESC;
