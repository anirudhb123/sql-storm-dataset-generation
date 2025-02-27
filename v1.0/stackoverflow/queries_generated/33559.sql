WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title AS PostTitle,
        p.OwnerUserId,
        p.ParentId,
        0 AS Level,
        p.CreationDate
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with questions

    UNION ALL

    SELECT 
        p2.Id,
        p2.Title,
        p2.OwnerUserId,
        p2.ParentId,
        Level + 1,
        p2.CreationDate
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePostHierarchy rph ON p2.ParentId = rph.PostId 
)
SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COALESCE(SUM(vt.Score), 0) AS TotalVotes,
    COALESCE(SUM(CASE WHEN bh.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
    COALESCE(SUM(CASE WHEN bh.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
    COALESCE(SUM(CASE WHEN bh.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
    ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes vt ON p.Id = vt.PostId
LEFT JOIN 
    Badges bh ON u.Id = bh.UserId 
WHERE 
    u.Reputation > 0
GROUP BY 
    u.Id
HAVING 
    COUNT(DISTINCT p.Id) > 5  -- Users with more than 5 posts
ORDER BY 
    TotalVotes DESC,
    TotalPosts DESC
LIMIT 10;

-- Performance Analysis: This query retrieves the top 10 users with the highest vote counts, 
-- who have also made more than 5 posts. It provides an interesting insight into 
-- the correlation between user activity and reputation, factoring in their earned 
-- badges as well. The use of recursive CTE helps visualize post hierarchies, 
-- while various aggregations provide key metrics. 
