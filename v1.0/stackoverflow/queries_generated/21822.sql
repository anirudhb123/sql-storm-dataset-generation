WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Rank,
    rp.CommentCount,
    COALESCE(b.Name, 'No Badge') AS BadgeName,
    CASE 
        WHEN rp.ViewCount IS NULL THEN 'No Views'
        WHEN rp.ViewCount > 100 THEN 'High View Count'
        ELSE 'Moderate View Count'
    END AS ViewStatus,
    STRING_AGG(t.TagName, ', ') AS Tags
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.PostId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Date = (SELECT MAX(Date) FROM Badges WHERE UserId = u.Id)
LEFT JOIN 
    LATERAL (
        SELECT 
            unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS TagName
        FROM 
            Posts p
        WHERE 
            p.Id = rp.PostId
    ) t ON TRUE
WHERE 
    rp.Rank <= 5
    AND (rp.Score > 10 OR rp.ViewCount IS NOT NULL)
ORDER BY 
    rp.CreationDate DESC;

-- Additional complexity
WITH PostTypeCounts AS (
    SELECT 
        PostTypeId,
        COUNT(*) AS TotalPosts
    FROM 
        Posts
    GROUP BY 
        PostTypeId
)

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostsMade,
    COALESCE(ptc.TotalPosts, 0) AS TotalPosts,
    COALESCE(SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS TotalComments
FROM 
    Posts p
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    PostTypeCounts ptc ON p.PostTypeId = ptc.PostTypeId
GROUP BY 
    pt.Name, ptc.TotalPosts
HAVING 
    COUNT(p.Id) > 1
ORDER BY 
    TotalComments DESC;

-- Merging post history changes with user actions
SELECT 
    ph.PostId,
    ph.PostHistoryTypeId,
    ph.UserId,
    u.DisplayName,
    MAX(ph.CreationDate) AS LastModified,
    COUNT(CASE WHEN ph.Comment IS NOT NULL THEN 1 END) AS TotalComments
FROM 
    PostHistory ph
JOIN 
    Users u ON ph.UserId = u.Id
GROUP BY 
    ph.PostId, ph.PostHistoryTypeId, ph.UserId, u.DisplayName
HAVING 
    COUNT(*) > 3
    AND MAX(ph.CreationDate) > NOW() - INTERVAL '1 year'
ORDER BY 
    LastModified DESC;

-- Identifying users with a significant number of badge changes
WITH UserBadgeChanges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeChangeCount
    FROM 
        Badges
    GROUP BY 
        UserId
)

SELECT 
    u.DisplayName,
    ubc.BadgeChangeCount
FROM 
    Users u
JOIN 
    UserBadgeChanges ubc ON u.Id = ubc.UserId
WHERE 
    ubc.BadgeChangeCount > 5
    AND u.Reputation > 100
ORDER BY 
    ubc.BadgeChangeCount DESC;
