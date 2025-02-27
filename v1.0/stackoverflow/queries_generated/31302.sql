WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Looking for Questions only

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.ParentId,
        ph.Title,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy ph ON p.ParentId = ph.PostId
),
UserPostAggregates AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS UpvotedPosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS DownvotedPosts,
        COALESCE(SUM(CASE WHEN ph.Level IS NOT NULL THEN 1 ELSE 0 END), 0) AS TotalAnswered
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        RecursivePostHierarchy ph ON p.AcceptedAnswerId = ph.PostId
    GROUP BY 
        u.Id
), 
RecentBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Date >= NOW() - INTERVAL '1 year' -- Get badges assigned in the last year
    GROUP BY 
        b.UserId
)
SELECT 
    ua.DisplayName,
    ua.TotalPosts,
    ua.UpvotedPosts,
    ua.DownvotedPosts,
    CASE 
        WHEN ua.TotalPosts > 0 THEN 
            ROUND((ua.UpvotedPosts::numeric / ua.TotalPosts) * 100, 2) 
        ELSE 0 
    END AS UpvotePercentage,
    rb.BadgeNames,
    (SELECT COUNT(*) 
     FROM Posts p 
     WHERE p.OwnerUserId = ua.UserId 
        AND p.PostTypeId = 1 
        AND p.CreationDate > NOW() - INTERVAL '1 month') AS RecentQuestions
FROM 
    UserPostAggregates ua
LEFT JOIN 
    RecentBadges rb ON ua.UserId = rb.UserId
ORDER BY 
    UpvotePercentage DESC, 
    ua.TotalPosts DESC;
