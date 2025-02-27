WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(p.UpVotes), 0) AS TotalUpVotes,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    ups.TotalViews,
    ups.TotalUpVotes,
    ups.PostCount,
    ub.TotalBadges,
    ub.HighestBadgeClass,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount
FROM 
    UserPostStats ups
LEFT JOIN 
    UserBadges ub ON ups.UserId = ub.UserId
LEFT JOIN 
    RankedPosts rp ON ups.UserId = rp.OwnerUserId AND rp.rn = 1
WHERE 
    ups.TotalViews > 1000 
    AND (ub.TotalBadges IS NULL OR ub.TotalBadges > 5)
ORDER BY 
    ups.TotalViews DESC, 
    ups.TotalUpVotes DESC
LIMIT 10;

