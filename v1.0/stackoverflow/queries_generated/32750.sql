WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        Id, 
        Reputation, 
        CreationDate, 
        DisplayName,
        LastAccessDate,
        0 AS Level
    FROM 
        Users
    WHERE 
        Reputation > 1000  -- Starting point: users with reputation greater than 1000
    
    UNION ALL
    
    SELECT 
        u.Id, 
        u.Reputation, 
        u.CreationDate, 
        u.DisplayName,
        u.LastAccessDate,
        ur.Level + 1
    FROM 
        Users u
    JOIN 
        UserReputationCTE ur ON ur.Reputation < u.Reputation
    WHERE 
        u.Reputation < 10000  -- Limiting the recursion to a certain reputation
)
SELECT 
    u.DisplayName, 
    u.Reputation,
    COUNT(p.Id) AS PostCount,
    SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
    SUM(CASE WHEN ph.Id IS NOT NULL THEN 1 ELSE 0 END) as PostsWithHistory,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    LATERAL (
        SELECT 
            unnest(string_to_array(p.Tags, ',')) AS TagName
    ) t ON true
WHERE 
    u.LastAccessDate >= NOW() - INTERVAL '1 year'  -- Users accessed recently
GROUP BY 
    u.Id
ORDER BY 
    u.Reputation DESC, 
    PostCount DESC
LIMIT 10;
