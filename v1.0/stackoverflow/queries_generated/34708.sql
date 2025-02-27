WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title AS PostTitle,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Select only Questions as base

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.Title AS PostTitle,
        a.ParentId,
        rh.Level + 1 AS Level
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostHierarchy rh ON a.ParentId = rh.PostId
    WHERE 
        a.PostTypeId = 2  -- Select only Answers
),
AggregatedPostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(p.Score) AS AverageScore,
        DENSE_RANK() OVER (ORDER BY SUM(COALESCE(p.Score, 0)) DESC) AS Rank
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
PostCloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- Only consider close and reopen events
    GROUP BY 
        ph.PostId
),
UserWithBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        b.Class = 1  -- Only consider Gold badges
    GROUP BY 
        u.Id
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    apps.TotalPosts,
    apps.TotalScore,
    apps.AverageScore,
    apps.Rank,
    COALESCE(pr.CloseReasons, 'No Close Reasons') AS CloseReasonDetails,
    ub.BadgeCount,
    ub.BadgeNames
FROM 
    Users u
LEFT JOIN 
    AggregatedPostStats apps ON u.Id = apps.OwnerUserId
LEFT JOIN 
    PostCloseReasons pr ON pr.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)
LEFT JOIN 
    UserWithBadges ub ON u.Id = ub.UserId
WHERE 
    apps.TotalPosts > 0 OR ub.BadgeCount > 0  -- Filter users with at least one post or a badge
ORDER BY 
    apps.Rank, u.DisplayName -- Rank users primarily by aggregate score, then alphabetically by display name
LIMIT 100;  -- Fetch top 100 users for performance evaluation
