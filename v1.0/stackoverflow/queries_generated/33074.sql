WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.OwnerUserId,
        p.CreationDate,
        p.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Start with Questions
    
    UNION ALL
    
    SELECT 
        a.Id AS PostId,
        a.Title,
        a.PostTypeId,
        a.OwnerUserId,
        a.CreationDate,
        a.AcceptedAnswerId,
        Level + 1
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostHierarchy r ON a.ParentId = r.PostId
    WHERE 
        a.PostTypeId = 2 -- Join Answers
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT rp.PostId) as TotalPosts,
    SUM(CASE WHEN rp.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN rp.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    AVG(COALESCE(p.ViewCount, 0)) AS AverageViewCount,
    STRING_AGG(DISTINCT COALESCE(t.TagName, '<None>'), ', ') AS TagsUsed,
    MAX(rp.CreationDate) AS LastPostDate,
    SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
    CASE 
        WHEN COUNT(DISTINCT rp.PostId) = 0 THEN 'No Posts'
        WHEN COUNT(DISTINCT rp.PostId) < 10 THEN 'Low Activity'
        ELSE 'High Activity'
    END AS ActivityLevel
FROM 
    Users u 
LEFT JOIN 
    RecursivePostHierarchy rp ON u.Id = rp.OwnerUserId
LEFT JOIN 
    Posts p ON rp.PostId = p.Id
LEFT JOIN 
    PostLinks pl ON pl.PostId = rp.PostId
LEFT JOIN 
    Tags t ON t.Id = pl.RelatedPostId
LEFT JOIN 
    Votes v ON v.PostId = rp.PostId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
HAVING 
    COUNT(DISTINCT rp.PostId) > 0
ORDER BY 
    TotalPosts DESC, u.Reputation DESC;
