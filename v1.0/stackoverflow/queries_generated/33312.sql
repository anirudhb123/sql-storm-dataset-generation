WITH RecursiveCTE AS (
    SELECT
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        1 AS Level,
        CAST(p.Title AS VARCHAR(MAX)) AS FullHierarchy
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    UNION ALL
    SELECT
        a.Id,
        a.Title,
        a.OwnerUserId,
        a.CreationDate,
        r.Level + 1,
        CAST(r.FullHierarchy + ' -> ' + a.Title AS VARCHAR(MAX))
    FROM 
        Posts a
    INNER JOIN 
        Posts q ON a.ParentId = q.Id
    INNER JOIN 
        RecursiveCTE r ON q.Id = r.Id
)
SELECT
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS TotalQuestions,
    SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswersCount,
    AVG(COALESCE(DATEDIFF(MINUTE, p.CreationDate, p.LastActivityDate), 0)) AS AvgTimeToFirstAnswer,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    RANK() OVER (ORDER BY SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) DESC) AS RankByAcceptedAnswers
FROM
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    STRING_TO_ARRAY(p.Tags, ',') AS t ON t.Id = p.Id
WHERE 
    u.Reputation > 1000 AND 
    p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
GROUP BY 
    u.Id
HAVING 
    COUNT(DISTINCT p.Id) > 5
ORDER BY 
    RankByAcceptedAnswers, TotalQuestions DESC;
