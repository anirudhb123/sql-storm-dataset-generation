WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.AcceptedAnswerId, 
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Select only Questions
    UNION ALL
    SELECT 
        p2.Id AS PostId, 
        p2.Title, 
        p2.AcceptedAnswerId, 
        p2.ParentId,
        r.Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePostHierarchy r ON p2.ParentId = r.PostId
)
SELECT 
    u.DisplayName AS UserDisplayName,
    COUNT(DISTINCT rph.PostId) AS TotalQuestions,
    COUNT(rph.PostId) FILTER (WHERE rph.AcceptedAnswerId IS NOT NULL) AS QuestionsWithAcceptedAnswers,
    SUM(p.ViewCount) AS TotalViews,
    AVG(p.Score) AS AverageScore,
    STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypes,
    MAX(b.Date) AS LastBadgeDate,
    CASE 
        WHEN COUNT(DISTINCT p.Id) > 10 THEN 'Active Top Contributor'
        ELSE 'Less Active'
    END AS ContributorLevel
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    RecursivePostHierarchy rph ON rph.PostId = p.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    u.Reputation > 1000 
GROUP BY 
    u.Id, u.DisplayName
HAVING 
    SUM(NULLIF(p.ViewCount, 0)) > 1000
ORDER BY 
    TotalViews DESC, 
    u.DisplayName;
