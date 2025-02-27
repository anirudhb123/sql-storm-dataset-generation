WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.OwnerUserId, 
        p.ParentId, 
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions

    UNION ALL

    SELECT 
        p.Id, 
        p.Title, 
        p.OwnerUserId, 
        p.ParentId, 
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.PostId  -- Joining to find answers
)
SELECT 
    u.DisplayName AS UserName, 
    COUNT(DISTINCT p.Id) AS TotalPosts, 
    COUNT(DISTINCT c.Id) AS TotalComments,
    SUM(v.BountyAmount) AS TotalBounty,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags,
    MAX(ph.CreationDate) AS LastActiveDate,
    AVG(DATEDIFF(NOW(), ph.CreationDate)) AS AvgPostAge,
    PERCENT_RANK() OVER (PARTITION BY u.Id ORDER BY COUNT(DISTINCT p.Id) DESC) AS PostRank
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 9)  -- Including only upvotes and bounties
LEFT JOIN 
    PostLinks pl ON p.Id = pl.PostId
LEFT JOIN 
    Tags t ON t.Id = ANY(string_to_array(p.Tags, ',')::int[])  -- Assuming Tags is a comma-separated string of IDs
LEFT JOIN 
    RecursivePostHierarchy rph ON rph.PostId = p.Id
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    u.Reputation > 1000 -- Filtering users with significant reputation
    AND (p.CreationDate >= NOW() - INTERVAL '1 year' OR rph.Level > 0) -- Only consider recent or those who have replies
GROUP BY 
    u.Id
ORDER BY 
    TotalPosts DESC, TotalComments DESC;
