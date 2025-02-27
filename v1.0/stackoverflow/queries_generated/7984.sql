SELECT
    u.DisplayName AS UserName,
    COUNT(*) AS TotalPosts,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
    SUM(p.Score) AS TotalScore,
    AVG(p.ViewCount) AS AvgViewCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags,
    MAX(p.CreationDate) AS LastPostDate
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    STRING_TO_ARRAY(p.Tags, ',') AS tags ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = TRIM(tags)
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.Id
HAVING 
    COUNT(*) > 5
ORDER BY 
    TotalScore DESC;
