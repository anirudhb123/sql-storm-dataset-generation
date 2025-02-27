WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days' AND 
        p.PostTypeId IN (1, 2) -- Only Questions and Answers
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBountySpent
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.LastAccessDate >= NOW() - INTERVAL '6 months'
    GROUP BY 
        u.Id
),
UserPostStats AS (
    SELECT 
        au.UserId,
        au.DisplayName,
        COUNT(rp.PostId) AS PostsCreated,
        SUM(rp.Score) AS TotalPostScore,
        SUM(rp.ViewCount) AS TotalViews
    FROM 
        ActiveUsers au
    LEFT JOIN 
        RankedPosts rp ON au.UserId = rp.OwnerUserId
    GROUP BY 
        au.UserId, au.DisplayName
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.PostsCreated,
    ups.TotalPostScore,
    ups.TotalViews,
    au.TotalBadgeCount,
    au.TotalBountySpent
FROM 
    UserPostStats ups
JOIN 
    ActiveUsers au ON ups.UserId = au.UserId
ORDER BY 
    ups.TotalPostScore DESC, ups.TotalViews DESC
LIMIT 10;
