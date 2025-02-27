WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
), 
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    r.PostId,
    r.Title,
    r.Score,
    r.ViewCount,
    ua.DisplayName AS UserDisplayName,
    ua.TotalPosts,
    COALESCE(ua.TotalBounties, 0) AS TotalBounties,
    STRING_AGG(t.TagName, ', ') AS Tags
FROM 
    RankedPosts r
LEFT JOIN 
    Users u ON r.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
LEFT JOIN 
    UserActivity ua ON u.Id = ua.UserId
LEFT JOIN 
    Posts p ON r.PostId = p.Id
LEFT JOIN 
    Tags t ON t.WikiPostId = r.PostId
WHERE 
    r.rn = 1
GROUP BY 
    r.PostId, r.Title, r.Score, r.ViewCount, ua.DisplayName, ua.TotalPosts
ORDER BY 
    r.CreationDate DESC
LIMIT 100;
