WITH RECURSIVE UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.CreationDate,
        u.Reputation,
        1 AS Depth
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000

    UNION ALL

    SELECT 
        u.Id,
        u.DisplayName,
        u.CreationDate,
        u.Reputation,
        Depth + 1
    FROM 
        Users u
    JOIN 
        Votes v ON u.Id = v.UserId
    JOIN 
        Posts p ON v.PostId = p.Id
    WHERE 
        v.CreationDate > DATEADD(YEAR, -1, GETDATE()) 
        AND v.VoteTypeId = 2  -- Upvotes only for recent activity
)

, RecentPosts AS (
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
        p.CreationDate > DATEADD(MONTH, -6, GETDATE())
)

, UserBadges AS (
    SELECT 
        ub.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(b.Id) AS BadgeCount
    FROM
        Badges b
    JOIN 
        Users ub ON b.UserId = ub.Id
    GROUP BY 
        ub.UserId
)

SELECT 
    ua.DisplayName,
    ua.Reputation,
    COUNT(DISTINCT rp.PostId) AS TotalRecentPosts,
    STRING_AGG(DISTINCT ub.BadgeNames, ' | ') AS Badges,
    AVG(rp.Score) AS AvgPostScore,
    MAX(rp.CreationDate) AS MostRecentPost,
    CASE 
        WHEN COUNT(DISTINCT rp.PostId) > 5 THEN 'Active User'
        ELSE 'Less active'
    END AS ActivityStatus,
    COUNT(DISTINCT v.PostId) AS TotalUpvotes
FROM 
    UserActivity ua
LEFT JOIN 
    RecentPosts rp ON ua.UserId = rp.OwnerUserId
LEFT JOIN 
    UserBadges ub ON ua.UserId = ub.UserId
LEFT JOIN 
    Votes v ON v.UserId = ua.UserId AND v.VoteTypeId = 2  -- Upvotes
GROUP BY 
    ua.DisplayName, ua.Reputation
HAVING 
    COUNT(DISTINCT rp.PostId) > 0
ORDER BY 
    AvgPostScore DESC;
