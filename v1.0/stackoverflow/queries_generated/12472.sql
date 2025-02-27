-- Performance benchmarking query for Stack Overflow schema

-- Get total count of each PostType and average Score
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS TotalOwnedPosts,
    SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS TotalAcceptedAnswers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Performance impact of different PostHistoryTypes on the number of edits
SELECT 
    pht.Name AS PostHistoryType,
    COUNT(ph.Id) AS EditCount,
    AVG(TIMESTAMPDIFF(SECOND, p.CreationDate, ph.CreationDate)) AS AvgTimeToEditInSeconds
FROM 
    PostHistory ph
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
JOIN 
    Posts p ON ph.PostId = p.Id
WHERE 
    pht.PostHistoryTypeId IN (4, 5, 6, 24) -- Considering only Title, Body, and Tags edits
GROUP BY 
    pht.Name
ORDER BY 
    EditCount DESC;

-- User performance analysis based on Reputation and Total Posts contributed
SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS TotalPosts,
    SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
    SUM(COALESCE(p.Score, 0)) AS TotalScore
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
HAVING 
    TotalPosts > 0 -- Only users who have posted
ORDER BY 
    Reputation DESC, TotalPosts DESC;

-- Identify the top tags by usage in posts
SELECT 
    t.TagName,
    COUNT(p.Id) AS PostCount,
    SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
FROM 
    Tags t
LEFT JOIN 
    Posts p ON t.Id = ANY(string_to_array(p.Tags, ',')::int[]) -- Assuming Tags are stored as comma-separated values
GROUP BY 
    t.Id, t.TagName
ORDER BY 
    PostCount DESC;
