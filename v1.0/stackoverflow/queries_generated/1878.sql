WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        COUNT(c.Id) AS TotalComments,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id
)

SELECT 
    u.DisplayName,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    COALESCE(b.Name, 'No Badge') AS BadgeName,
    rp.TotalComments,
    CASE 
        WHEN rp.RankByScore <= 5 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Class = 1
WHERE 
    u.Reputation > (SELECT AVG(Reputation) FROM Users) 
    AND rp.TotalComments > 0
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;

WITH RecentHistory AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        ph.PostId
)

SELECT 
    p.Title, 
    rp.TotalComments, 
    COALESCE(rh.EditCount, 0) AS EditCount
FROM 
    Posts p
JOIN 
    RankedPosts rp ON p.Id = rp.Id
LEFT JOIN 
    RecentHistory rh ON p.Id = rh.PostId
WHERE 
    rp.RankByScore = 1
ORDER BY 
    EditCount DESC, rp.ViewCount DESC;
