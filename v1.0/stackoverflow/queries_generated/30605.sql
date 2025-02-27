WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        0 AS Level,
        p.OwnerUserId,
        p.CreationDate
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL -- Start from top-level posts (Questions)
    
    UNION ALL
    
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.Level + 1,
        p.OwnerUserId,
        p.CreationDate
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
    COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
    SUM(v.BountyAmount) AS TotalBounties,
    MAX(ph.Level) AS MaxPostLevel,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostLinks pl ON p.Id = pl.PostId
LEFT JOIN 
    Tags t ON t.Id IN (SELECT UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><'))::int)
                        WHERE t.Id IS NOT NULL)
LEFT JOIN 
    PostHierarchy ph ON p.Id = ph.PostId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
HAVING 
    COUNT(DISTINCT p.Id) > 0
ORDER BY 
    u.Reputation DESC;

-- This query gets performance benchmarks on users based on their post contributions,
-- hunting for maximum depth of discussions through recursive hierarchy while also aggregating data 
-- from related tables such as votes and tags to get richer insights.
