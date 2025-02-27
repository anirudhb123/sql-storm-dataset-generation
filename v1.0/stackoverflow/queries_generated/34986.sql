WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        1 AS Level
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000 -- Starting point for users with reputation > 1000

    UNION ALL

    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        Level + 1
    FROM 
        Users u
    INNER JOIN 
        UserReputationCTE ur ON ur.Reputation < u.Reputation
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT c.Id) AS TotalComments,
    SUM(v.BountyAmount) AS TotalBounty,
    COUNT(DISTINCT CASE WHEN b.Class = 1 THEN b.Id END) AS GoldBadges,
    COUNT(DISTINCT CASE WHEN b.Class = 2 THEN b.Id END) AS SilverBadges,
    COUNT(DISTINCT CASE WHEN b.Class = 3 THEN b.Id END) AS BronzeBadges
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON u.Id = c.UserId
LEFT JOIN 
    Votes v ON u.Id = v.UserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    u.Reputation IS NOT NULL
    AND (u.CreationDate >= NOW() - INTERVAL '1 year' OR u.Location LIKE 'USA%') 
GROUP BY 
    u.UserId, u.DisplayName, u.Reputation
HAVING 
    COUNT(DISTINCT p.Id) > 10
ORDER BY 
    u.Reputation DESC, TotalPosts DESC
LIMIT 100;

-- Performance Benchmarking
EXPLAIN ANALYZE
SELECT 
    u.UserId,
    u.DisplayName,
    (SELECT COALESCE(AVG(Score), 0) FROM Posts WHERE OwnerUserId = u.Id) AS AvgPostScore,
    ROW_NUMBER() OVER(PARTITION BY u.Location ORDER BY u.Reputation DESC) AS RankByLocation,
    STRING_AGG(DISTINCT tag.TagName, ', ') AS TagsContributed
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    LATERAL (
        SELECT 
            DISTINCT unnest(string_to_array(p.Tags, ',')) AS TagName
        FROM 
            Posts
        WHERE 
            Posts.Id = p.Id
    ) AS tag ON true
WHERE 
    u.CreationDate <= (CURRENT_DATE - INTERVAL '5 years')
GROUP BY 
    u.UserId, u.DisplayName
HAVING 
    AvgPostScore > 1
ORDER BY 
    RankByLocation, u.Reputation DESC;
