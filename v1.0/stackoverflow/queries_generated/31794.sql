WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        cte.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE cte ON p.ParentId = cte.PostId
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScores,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeScores
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS Badges,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistoryTypesCounts AS (
    SELECT 
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        ph.PostHistoryTypeId
)

SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalViews,
    ups.PositiveScores,
    ups.NegativeScores,
    COALESCE(ub.Badges, 'No Badges') AS Badges,
    phc.HistoryCount,
    RANK() OVER (ORDER BY ups.TotalViews DESC) AS ViewRank,
    ROW_NUMBER() OVER (PARTITION BY ups.UserId ORDER BY ups.TotalPosts DESC) AS PostRank
FROM 
    UserPostStats ups
LEFT JOIN 
    UserBadges ub ON ups.UserId = ub.UserId
LEFT JOIN 
    PostHistoryTypesCounts phc ON TRUE
WHERE 
    ups.TotalPosts > 0
ORDER BY 
    ups.TotalViews DESC, ups.TotalPosts DESC;
