WITH RECURSIVE UserHierarchy AS (
    SELECT 
        Id, 
        DisplayName, 
        Reputation, 
        NULL AS ParentId
    FROM 
        Users
    WHERE 
        Reputation > 1000 -- Start with reputable users

    UNION ALL

    SELECT 
        u.Id, 
        u.DisplayName, 
        u.Reputation, 
        uh.Id AS ParentId
    FROM 
        Users u
    JOIN 
        UserHierarchy uh ON u.Reputation < uh.Reputation * 0.9 -- Only consider users with less than 90% of parent's reputation
)

SELECT 
    u.DisplayName AS UserName,
    u.Reputation AS UserReputation,
    COALESCE(dt.Name, 'N/A') AS DevelopmentType,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    AVG(v.Score) AS AverageScore,
    MAX(CASE WHEN ph.PostId IS NOT NULL THEN 'Post Historically Edited' ELSE 'No Edit History' END) AS EditStatus,
    STRING_AGG(DISTINCT t.TagName, ', ') AS UserTags
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Tags t ON t.ExcerptPostId = p.Id
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId AND (ph.PostHistoryTypeId IN (4, 5, 6, 24))
LEFT JOIN 
    PostTypes dt ON p.PostTypeId = dt.Id
WHERE 
    u.Reputation IS NOT NULL
GROUP BY 
    u.Id, u.DisplayName, u.Reputation, dt.Name
ORDER BY 
    UserReputation DESC, TotalPosts DESC
LIMIT 10; -- Limit results to the top 10 users based on their reputation
