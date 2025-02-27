
SELECT 
    u.DisplayName AS UserDisplayName,
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COALESCE(SUM(CASE WHEN bh.UserId IS NOT NULL THEN 1 ELSE 0 END), 0) AS TotalBadges,
    AVG(u.Reputation) AS AverageUserReputation,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Badges bh ON u.Id = bh.UserId
LEFT JOIN 
    STRING_SPLIT(p.Tags, ',') AS tag_name ON tag_name.value IS NOT NULL
JOIN 
    Tags t ON t.TagName = LTRIM(RTRIM(tag_name.value))
WHERE 
    p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL '1 year'
    AND p.PostTypeId = 1
GROUP BY 
    u.DisplayName, p.Title, p.CreationDate, u.Reputation
ORDER BY 
    TotalVotes DESC, AverageUserReputation DESC;
