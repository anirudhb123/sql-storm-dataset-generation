WITH RECURSIVE UserPostHierarchy AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName AS UserName,
        p.Id AS PostId,
        p.Title AS PostTitle,
        p.CreationDate AS PostCreationDate,
        1 AS Level
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000

    UNION ALL
    
    SELECT 
        u.Id AS UserId,
        u.DisplayName AS UserName,
        p.Id AS PostId,
        p.Title AS PostTitle,
        p.CreationDate AS PostCreationDate,
        uh.Level + 1
    FROM 
        UserPostHierarchy uh
    JOIN 
        Posts p ON uh.PostId = p.ParentId
    JOIN 
        Users u ON p.OwnerUserId = u.Id
)
SELECT 
    uh.UserId,
    uh.UserName,
    COUNT(DISTINCT uh.PostId) AS TotalPosts,
    COUNT(DISTINCT CASE WHEN pt.Name = 'Answer' THEN uh.PostId END) AS TotalAnswers,
    COUNT(DISTINCT CASE WHEN pt.Name = 'Question' THEN uh.PostId END) AS TotalQuestions,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AllTags,
    AVG(u.Reputation) AS AverageReputation,
    MAX(uh.PostCreationDate) AS LastPostDate,
    COALESCE(MIN(uh.PostCreationDate), 'No Posts') AS FirstPostDate
FROM 
    UserPostHierarchy uh
LEFT JOIN 
    PostTypes pt ON pt.Id = (SELECT PostTypeId FROM Posts WHERE Id = uh.PostId)
LEFT JOIN 
    Posts p ON uh.PostId = p.Id
LEFT JOIN 
    Tags t ON t.Id = ANY(string_to_array(p.Tags, ',')::int[])  -- Tags association using PostgreSQL array functions
LEFT JOIN 
    Users u ON uh.UserId = u.Id
GROUP BY 
    uh.UserId, uh.UserName, uh.Level
HAVING 
    COUNT(DISTINCT uh.PostId) > 5  -- Only users with more than 5 posts in the hierarchy
ORDER BY 
    TotalPosts DESC, AverageReputation DESC;
