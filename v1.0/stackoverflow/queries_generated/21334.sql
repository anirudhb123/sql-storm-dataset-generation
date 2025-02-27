WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByOwner,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.PostTypeId
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        SUM(CASE WHEN p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 month' THEN 1 ELSE 0 END) AS RecentPosts,
        MAX(p.CreationDate) AS LastActive
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    au.DisplayName,
    au.TotalBadges,
    au.RecentPosts,
    COALESCE(rp.PostId, -1) AS LastPostId,
    rp.Title AS LastPostTitle,
    rp.CreationDate AS LastPostDate,
    rp.CommentCount AS LastPostComments,
    rp.TotalBounty,
    CASE WHEN rp.RankByScore IS NULL THEN 'No Posts' ELSE 'Has Posts' END AS PostStatus
FROM 
    ActiveUsers au
LEFT JOIN 
    RankedPosts rp ON au.UserId = rp.OwnerUserId AND rp.RankByOwner = 1
ORDER BY 
    au.TotalBadges DESC, 
    au.RecentPosts DESC, 
    au.LastActive DESC;
