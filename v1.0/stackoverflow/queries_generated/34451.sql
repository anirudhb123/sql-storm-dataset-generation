WITH RecursivePostCTE AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        1 AS Level,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        COALESCE(p.AcceptedAnswerId, -1),
        rp.Level + 1,
        p.OwnerUserId
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE rp ON p.ParentId = rp.Id
)

SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS QuestionCount,
    SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
    SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedCount,
    SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosureCount,
    MAX(ph.CreationDate) AS LastClosureDate,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COUNT(DISTINCT p.Id) DESC) AS UserRank
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1  -- Questions
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10  -- Closed Posts
LEFT JOIN 
    Tags t ON t.Id IN (SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))::int) ) 
WHERE 
    u.Reputation > 50  -- Only include users with high reputation
GROUP BY 
    u.DisplayName,
    u.Reputation
HAVING 
    COUNT(DISTINCT p.Id) > 5  -- Only include users with more than 5 questions
ORDER BY 
    TotalViews DESC, UserRank;
