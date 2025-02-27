WITH RECURSIVE PostHierarchy AS (
    SELECT 
        Id AS PostId,
        ParentId,
        Title,
        1 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Starting with questions
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
)

SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    p.Title AS PostTitle,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(v.BountyAmount) AS TotalBounty,
    CASE
        WHEN p.ClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    STRING_AGG(t.TagName, ', ') AS Tags,
    LAG(p.CreationDate) OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate) AS PreviousPostDate,
    ph.Level AS PostLevel
FROM 
    Users u
INNER JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Tags t ON t.Id IN (SELECT UNNEST(string_to_array(substr(p.Tags, 2, length(p.Tags)-2), '>,<'))::int[])
                        WHERE t.TagName IS NOT NULL)
LEFT JOIN 
    PostHierarchy ph ON p.Id = ph.PostId
WHERE 
    u.Reputation > 1000  -- Only considering users with reputation greater than 1000
GROUP BY 
    u.DisplayName, u.Reputation, p.Title, p.ClosedDate, ph.Level
ORDER BY 
    TotalBounty DESC, CommentCount DESC;
