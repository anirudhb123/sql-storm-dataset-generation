WITH RecursiveTagHierarchy AS (
    SELECT 
        Id,
        TagName,
        Count,
        0 AS Level,
        CAST(TagName AS VARCHAR(255)) AS FullPath
    FROM 
        Tags
    WHERE 
        IsModeratorOnly = 0 -- Only consider non-moderator tags

    UNION ALL

    SELECT 
        t.Id,
        t.TagName,
        t.Count,
        r.Level + 1,
        CAST(r.FullPath || ' > ' || t.TagName AS VARCHAR(255))
    FROM 
        Tags t
    INNER JOIN 
        RecursiveTagHierarchy r ON t.ExcerptPostId = r.Id
)
SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS PostCount,
    COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
    COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
    MAX(p.CreationDate) AS LastPostDate,
    STRING_AGG(DISTINCT rt.FullPath, ', ') AS RelatedTags,
    RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS UserRank,
    ROW_NUMBER() OVER (PARTITION BY YEAR(p.CreationDate) ORDER BY SUM(p.Score) DESC) AS YearScoreRank
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    PostLinks pl ON p.Id = pl.PostId
LEFT JOIN 
    RecursiveTagHierarchy rt ON pl.RelatedPostId = rt.Id
WHERE 
    u.Reputation > 1000 
    AND p.CreationDate >= NOW() - INTERVAL '5 years' 
    AND (p.ClosedDate IS NULL OR (p.ClosedDate IS NOT NULL AND p.LastActivityDate > p.ClosedDate))
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
HAVING 
    COUNT(DISTINCT p.Id) > 10
ORDER BY 
    UserRank,
    LastPostDate DESC
LIMIT 50;
