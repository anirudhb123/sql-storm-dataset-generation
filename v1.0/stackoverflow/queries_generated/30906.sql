WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        CreationDate,
        Score,
        ROW_NUMBER() OVER (PARTITION BY Id ORDER BY CreationDate DESC) AS RowNum
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON rph.Id = p.ParentId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName AS UserName,
    SUM(COALESCE(p.Score, 0)) AS TotalScore,
    COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount,
    COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount,
    COUNT(DISTINCT ph.Id) AS PostHistoryCount,
    ARRAY_AGG(DISTINCT pt.Name) AS PostTypeNames,
    COUNT(DISTINCT t.Id) AS TagCount,
    MAX(p.CreationDate) AS MostRecentActivity
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    LATERAL (SELECT DISTINCT unnest(string_to_array(p.Tags, '><')) AS TagName) t ON true
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    u.Reputation > 100 AND
    u.CreationDate < NOW() - INTERVAL '1 year'
GROUP BY 
    u.Id, u.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) > 5
ORDER BY 
    TotalScore DESC
LIMIT 100;

-- A UNION of metrics filtered by score and creation date
SELECT 
    'Metrics by Score' AS MetricType,
    COUNT(*) AS TotalUsers,
    AVG(u.Reputation) AS AverageReputation
FROM 
    Users u
WHERE 
    u.Reputation > 100
UNION ALL
SELECT 
    'Metrics by Date',
    COUNT(*) AS TotalUsers,
    AVG(u.Reputation) AS AverageReputation
FROM 
    Users u
WHERE 
    u.CreationDate < NOW() - INTERVAL '1 year';
