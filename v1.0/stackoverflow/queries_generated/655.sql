WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Score > 0
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(v.BountyAmount) AS TotalBounty,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  -- Count only BountyStart votes
    GROUP BY 
        u.Id
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalBounty,
    ua.TotalComments,
    COALESCE(rp.Title, 'No Recent Posts') AS RecentPostTitle,
    COALESCE(rp.CreationDate, 'N/A') AS RecentPostDate,
    COALESCE(rp.Score, 0) AS RecentPostScore
FROM 
    UserActivity ua
LEFT JOIN 
    RankedPosts rp ON ua.UserId = rp.OwnerUserId AND rp.rn = 1
WHERE 
    ua.TotalPosts > 5
ORDER BY 
    ua.TotalBounty DESC, 
    ua.TotalPosts DESC
LIMIT 10;
