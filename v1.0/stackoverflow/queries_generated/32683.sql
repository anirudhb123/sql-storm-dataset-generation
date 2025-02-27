WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.LastActivityDate,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Selecting only questions as starting point

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.LastActivityDate,
        p.OwnerUserId,
        rp.Level + 1
    FROM 
        Posts p
    JOIN 
        RecursivePostCTE rp ON p.ParentId = rp.PostId
)

SELECT 
    u.DisplayName AS UserDisplayName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPosts,
    AVG(p.ViewCount) AS AvgViews,
    MAX(CASE WHEN bh.Class = 1 THEN bh.Name END) AS GoldBadge,
    MAX(CASE WHEN bh.Class = 2 THEN bh.Name END) AS SilverBadge,
    MAX(CASE WHEN bh.Class = 3 THEN bh.Name END) AS BronzeBadge,
    COUNT(DISTINCT b.Id) AS TotalBadges,
    ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COUNT(p.Id) DESC) AS RankPosts,
    STRING_AGG(DISTINCT CONCAT('(', p.Id, ') ', p.Title), '; ') AS PostTitlesConcatenated
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    RecursivePostCTE r ON p.Id = r.PostId
LEFT JOIN 
    PostHistory ph ON ph.UserId = u.Id AND ph.PostId = p.Id
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE 
    u.Reputation > 100 AND (u.Location IS NOT NULL OR u.WebsiteUrl IS NOT NULL)
GROUP BY 
    u.Id, u.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) > 5
ORDER BY 
    TotalPosts DESC, AvgViews DESC
FETCH FIRST 10 ROWS ONLY;
