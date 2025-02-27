
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
),

PostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(NULLIF(p.ViewCount, 0)) AS AvgViewsPerPost
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),

ActiveBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Date >= DATEADD(month, -6, '2024-10-01 12:34:56')
    GROUP BY 
        b.UserId
),

RecentActivities AS (
    SELECT 
        ph.UserId,
        MAX(ph.CreationDate) AS LastActivityDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13)
    GROUP BY 
        ph.UserId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    ps.TotalPosts,
    ps.TotalScore,
    ps.TotalViews,
    ps.AvgViewsPerPost,
    ab.BadgeCount,
    ab.BadgeNames,
    ra.LastActivityDate,
    CASE 
        WHEN ra.LastActivityDate IS NULL THEN 'Inactive'
        ELSE 'Active'
    END AS UserStatus,
    STRING_AGG(DISTINCT rp.Title, ', ') AS TopPosts
FROM 
    Users u
LEFT JOIN 
    PostStats ps ON u.Id = ps.UserId
LEFT JOIN 
    ActiveBadges ab ON u.Id = ab.UserId
LEFT JOIN 
    RecentActivities ra ON u.Id = ra.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName, ps.TotalPosts, ps.TotalScore, ps.TotalViews, ps.AvgViewsPerPost, ab.BadgeCount, ab.BadgeNames, ra.LastActivityDate
ORDER BY 
    ps.TotalScore DESC, ps.TotalPosts DESC;
