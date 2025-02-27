WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.AnswerCount, 
        p.ParentId, 
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions

    UNION ALL

    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.AnswerCount, 
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.PostId
)

SELECT 
    u.DisplayName AS UserName,
    SUM(COALESCE(p.Score, 0)) AS TotalScore,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(CASE WHEN p.PostTypeId = 1 THEN p.AnswerCount ELSE 0 END) AS QuestionCount,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
    COUNT(DISTINCT ph.Id) AS HistoryCount,
    MAX(COALESCE(ph.CreationDate, p.CreationDate)) AS MostRecentActivity,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed
FROM 
    Users u
LEFT OUTER JOIN 
    Posts p ON p.OwnerUserId = u.Id
LEFT OUTER JOIN 
    PostHistory ph ON ph.PostId = p.Id
LEFT OUTER JOIN 
    Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
LEFT OUTER JOIN 
    RecursivePostHierarchy rph ON p.Id = rph.PostId
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) > 10 
    AND AVG(p.Score) > 5
ORDER BY 
    TotalScore DESC;
