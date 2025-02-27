WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerUserId,
        rp.CreationDate,
        rp.ViewCount,
        ur.Reputation,
        ur.DisplayName,
        ur.TotalBounty,
        ur.BadgeCount
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    WHERE 
        rp.UserPostRank = 1
)
SELECT 
    pd.Title,
    pd.ViewCount,
    pd.Reputation AS UserReputation,
    pd.TotalBounty,
    pd.BadgeCount,
    CASE 
        WHEN pd.ViewCount IS NULL THEN 'Unviewed Post'
        WHEN pd.ViewCount > 1000 THEN 'Popular Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    PostDetails pd
LEFT JOIN 
    Comments c ON pd.PostId = c.PostId
WHERE 
    pd.Reputation > 1000
ORDER BY 
    pd.ViewCount DESC, pd.Reputation DESC
LIMIT 50;
