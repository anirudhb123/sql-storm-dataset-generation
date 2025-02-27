WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPosts,
        AVG(v.BountyAmount) AS AverageBounty 
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8
    WHERE 
        u.Reputation > 50 
    GROUP BY 
        u.Id, u.DisplayName
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(ph.UserId, -1) AS LastEditorId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 4
)

SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalBadges,
    ua.PositivePosts,
    ua.PopularPosts,
    ua.AverageBounty,
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.Score,
    pm.LastEditorId
FROM 
    UserActivity ua
LEFT JOIN 
    PostMetrics pm ON ua.UserId = pm.LastEditorId
WHERE 
    ua.TotalPosts > 10 
    AND (pm.Score IS NULL OR pm.Score > 0)
ORDER BY 
    ua.TotalPosts DESC, ua.AverageBounty DESC, pm.Score DESC
LIMIT 50;
