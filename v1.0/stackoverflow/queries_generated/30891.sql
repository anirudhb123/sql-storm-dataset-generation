WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        ParentId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        1 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.Id
),
UserPostStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(p.Score, 0)) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
ActiveUserPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RecentEdit
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 10) -- edit title, edit body, post closed
),
TopActiveUsers AS (
    SELECT 
        UserId,
        COUNT(PostId) AS EditCount
    FROM 
        ActiveUserPostHistory
    WHERE 
        RecentEdit = 1
    GROUP BY 
        UserId
    HAVING 
        COUNT(PostId) > 5
),
MostActiveUsersWithBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    INNER JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(b.Id) >= 2
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.PostCount,
    ups.TotalViews,
    ups.AvgScore,
    topEdits.EditCount,
    COALESCE(badges.BadgeCount, 0) AS BadgeCount
FROM 
    UserPostStatistics ups
LEFT JOIN 
    TopActiveUsers topEdits ON ups.UserId = topEdits.UserId
LEFT JOIN 
    MostActiveUsersWithBadges badges ON ups.UserId = badges.UserId
WHERE 
    ups.PostCount > 0
ORDER BY 
    ups.TotalViews DESC, ups.AvgScore DESC
LIMIT 10;
