WITH RecursivePostHierarchy AS (
    SELECT 
        Id, 
        PostTypeId, 
        AcceptedAnswerId, 
        ParentId, 
        Title, 
        0 AS Level,
        Score,
        CreationDate,
        Tags
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Start with Questions

    UNION ALL

    SELECT 
        p.Id, 
        p.PostTypeId, 
        p.AcceptedAnswerId, 
        p.ParentId, 
        p.Title, 
        Level + 1,
        p.Score,
        p.CreationDate,
        p.Tags
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    AVG(CASE WHEN p.PostTypeId = 1 THEN r.Score ELSE NULL END) AS AvgQuestionScore,
    MAX(p.CreationDate) AS LastActive,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed,
    COALESCE(b.Class, 0) AS BadgeClass,
    COALESCE(b.Name, 'No Badges') AS BadgeName
FROM 
    Users u
LEFT JOIN 
    Posts p ON p.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON b.UserId = u.Id
LEFT JOIN 
    (SELECT DISTINCT unnest(string_to_array(Tags, ', ')) AS TagName FROM Posts) t ON t.TagName IS NOT NULL
LEFT JOIN 
    RecursivePostHierarchy r ON r.Id = p.Id
WHERE 
    u.Reputation > 100  -- filter users with reputation greater than 100
GROUP BY 
    u.Id, u.DisplayName, b.Class, b.Name
HAVING 
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) > 5  -- Users must have more than 5 Questions
ORDER BY 
    TotalPosts DESC
LIMIT 50;

WITH MostRecentPosts AS (
    SELECT 
        Id,
        Title,
        CreationDate,
        ROW_NUMBER() OVER (PARTITION BY OwnerUserId ORDER BY CreationDate DESC) AS rn
    FROM 
        Posts
    WHERE 
        ClosedDate IS NULL  -- Only open posts
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    p.Title,
    p.CreationDate
FROM 
    Users u
JOIN 
    MostRecentPosts p ON u.Id = p.OwnerUserId
WHERE 
    p.rn = 1  -- Most recent post for each user
ORDER BY 
    p.CreationDate DESC;

-- Performance benchmarking metrics
SELECT 
    COUNT(*) AS TotalUsers,
    SUM(CASE WHEN Reputation > 100 THEN 1 ELSE 0 END) AS ActiveUsers,
    AVG(Reputation) AS AvgUserReputation,
    MIN(Score) AS MinPostScore,
    MAX(Score) AS MaxPostScore
FROM 
    Users
JOIN 
    Posts ON Users.Id = Posts.OwnerUserId
WHERE 
    Posts.CreationDate >= DATE_TRUNC('year', CURRENT_DATE)  -- Posts created this year
    AND Posts.ClosedDate IS NULL;  -- exclude closed posts
