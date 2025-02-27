WITH RECURSIVE TagHierarchy AS (
    SELECT 
        Id,
        TagName,
        Count,
        CAST(TagName AS VARCHAR(1000)) AS FullTagPath,
        1 AS Level
    FROM 
        Tags
    WHERE 
        IsModeratorOnly = 0

    UNION ALL

    SELECT 
        t.Id,
        t.TagName,
        t.Count,
        CONCAT(th.FullTagPath, ' > ', t.TagName),
        th.Level + 1
    FROM 
        Tags t
    INNER JOIN 
        PostLinks pl ON t.Id = pl.RelatedPostId
    INNER JOIN 
        TagHierarchy th ON pl.PostId = th.Id
)
SELECT 
    u.Id AS UserId,
    COUNT(DISTINCT p.Id) AS PostCount,
    SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
    SUM(CASE WHEN p.Score <= 0 THEN 1 ELSE 0 END) AS NegativePosts,
    ARRAY_AGG(DISTINCT th.FullTagPath) AS TagHierarchy,
    AVG(u.Reputation) AS AvgReputation
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON v.PostId = p.Id
LEFT JOIN 
    TagHierarchy th ON th.Id IN (SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')))::int)
WHERE 
    u.Reputation > 100
    AND p.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY 
    u.Id
ORDER BY 
    PostCount DESC
LIMIT 10;
