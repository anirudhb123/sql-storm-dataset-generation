WITH RECURSIVE TagHierarchy AS (
    SELECT 
        Id,
        TagName,
        Count,
        WikiPostId,
        1 AS Level
    FROM 
        Tags
    WHERE 
        IsModeratorOnly = 0  -- Limit to non-moderator-only tags

    UNION ALL

    SELECT 
        t.Id,
        t.TagName,
        t.Count,
        t.WikiPostId,
        th.Level + 1
    FROM 
        Tags t
    JOIN 
        PostLinks pl ON t.Id = pl.RelatedPostId
    JOIN 
        TagHierarchy th ON pl.PostId = th.Id
    WHERE 
        th.Level < 5  -- Limit recursion depth to prevent infinite loops
)
SELECT 
    th.TagName,
    th.Count,
    COUNT(DISTINCT p.Id) AS RelatedPostCount,
    SUM(CASE WHEN p.AccceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
    AVG(u.Reputation) AS AverageUserReputation,
    STRING_AGG(DISTINCT u.DisplayName, ', ') AS TopUsers,
    MAX(p.CreationDate) AS MostRecentPostDate
FROM 
    TagHierarchy th
LEFT JOIN 
    Posts p ON p.Tags LIKE '%' || th.TagName || '%'  -- String containment check for related posts
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    th.TagName,
    th.Count
ORDER BY 
    RelatedPostCount DESC
LIMIT 10;  -- Top 10 tags based on related post count
