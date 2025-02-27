WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Starting from Questions
    UNION ALL
    SELECT 
        p2.Id,
        p2.Title,
        p2.PostTypeId,
        p2.OwnerUserId,
        p2.AcceptedAnswerId,
        r.Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePostCTE r ON p2.ParentId = r.PostId -- Recursive join to find answers
)
SELECT 
    u.DisplayName,
    COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionsCount,
    COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswersCount,
    COUNT(DISTINCT b.Name) AS BadgesCount,
    COUNT(DISTINCT t.TagName) AS UniqueTagsCount,
    AVG(COALESCE(p.Score, 0)) AS AverageScore,
    MAX(p.CreationDate) AS LastActivityDate,
    NULLIF(MAX(p.LastEditDate), '1900-01-01') AS LastEditDate -- Handling NULL logic
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    (SELECT DISTINCT UNNEST(string_to_array(Tags, ',')) AS TagName FROM Posts) t ON t.TagName IS NOT NULL
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 6 -- Edit Tags in PostHistory
WHERE 
    u.Reputation > 1000 -- Users with high reputation
    AND (p.LastActivityDate >= CURRENT_DATE - INTERVAL '30 days' OR p.LastEditDate >= CURRENT_DATE - INTERVAL '30 days') -- Active posts
GROUP BY 
    u.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) > 5 -- At least 5 posts
ORDER BY 
    AverageScore DESC
LIMIT 10;

-- This query benchmarks users based on their contributions and engagement within the last 30 days,
-- utilizing outer joins, recursive CTEs, aggregated calculations, and complex predicates.
