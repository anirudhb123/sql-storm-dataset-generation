
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
    STRING_AGG(DISTINCT t.TagName, ',') AS Tags,
    COALESCE(b.BadgeCount, 0) AS UserBadges,
    u.Reputation,
    u.DisplayName
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    (SELECT 
         UserId, COUNT(*) AS BadgeCount 
     FROM 
         Badges 
     GROUP BY 
         UserId) b ON u.Id = b.UserId
LEFT JOIN 
    (SELECT value AS TagName, p.Id FROM Posts p CROSS APPLY STRING_SPLIT(p.Tags, ',')) t ON p.Id = t.Id
WHERE 
    p.CreationDate >= '2022-01-01' 
    AND p.PostTypeId = 1
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.Id, u.Reputation, u.DisplayName, b.BadgeCount
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
