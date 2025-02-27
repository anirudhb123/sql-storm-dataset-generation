WITH RecursivePostCTE AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start from questions
    
    UNION ALL
    
    SELECT 
        a.Id,
        a.Title,
        a.CreationDate,
        a.OwnerUserId,
        a.ParentId,
        Level + 1
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostCTE r ON a.ParentId = r.Id
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
    SUM(COALESCE(p.Score, 0)) AS TotalScore,
    COUNT(DISTINCT b.Id) AS TotalBadges,
    DATE_TRUNC('month', p.CreationDate) AS CreationMonth,
    AVG(CASE WHEN p.ViewCount > 0 THEN p.ViewCount ELSE NULL END) AS AvgViews,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    Tags t ON t.ExcerptPostId = p.Id
LEFT JOIN 
    PostHistory ph ON ph.PostId = p.Id
WHERE 
    u.Reputation > 100  -- Filter for users with reputation greater than 100
    AND p.CreationDate >= '2020-01-01'  -- Only consider posts from 2020 onward
GROUP BY 
    u.Id, u.DisplayName, u.Reputation, CreationMonth
HAVING 
    COUNT(DISTINCT p.Id) > 10  -- Only include users with more than 10 total posts
ORDER BY 
    TotalScore DESC, TotalPosts DESC;
