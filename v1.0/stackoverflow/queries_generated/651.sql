WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
ActiveUsers AS (
    SELECT 
        ur.UserId, 
        ur.DisplayName, 
        ur.Reputation,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.CommentCount
    FROM 
        UserReputation ur
    INNER JOIN 
        RankedPosts rp ON ur.UserId = rp.OwnerUserId
    WHERE 
        ur.Reputation > 1000 AND 
        rp.rn = 1
)

SELECT 
    au.DisplayName,
    au.Reputation,
    COUNT(DISTINCT p.Id) AS SuccessfulPosts,
    SUM(v.BountyAmount) AS TotalBounties,
    SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS TotalClosures
FROM 
    ActiveUsers au
LEFT JOIN 
    Posts p ON au.UserId = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- BountyStart or BountyClose
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
GROUP BY 
    au.DisplayName, 
    au.Reputation
HAVING 
    COUNT(DISTINCT p.Id) > 5
ORDER BY 
    TotalBounties DESC, 
    au.Reputation DESC
LIMIT 10;
