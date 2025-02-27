WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(rp.Title, 'No Recent Posts') AS RecentPostTitle,
    COALESCE(rp.CreationDate, '1970-01-01') AS RecentPostDate,
    COALESCE(rp.Score, 0) AS PostScore,
    ub.BadgeCount,
    CASE 
        WHEN ub.HighestBadgeClass = 1 THEN 'Gold Badge Holder'
        WHEN ub.HighestBadgeClass = 2 THEN 'Silver Badge Holder'
        WHEN ub.HighestBadgeClass = 3 THEN 'Bronze Badge Holder'
        ELSE 'No Badges'
    END AS BadgeStatus
FROM 
    Users u
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId 
                    AND rp.rn = 1
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM Votes v
        WHERE v.UserId = u.Id AND v.VoteTypeId = 3 -- check for downvotes
    )
ORDER BY 
    ub.BadgeCount DESC, u.Reputation DESC
LIMIT 50;

-- Explanation:
-- This query utilizes Common Table Expressions (CTEs) for organizing recent posts and user badges, 
-- employs window functions for ranking posts, incorporates outer joins to gather complete user details, 
-- and uses correlated subqueries to filter out users who have downvoted.
-- The result is a comprehensive overview of users who are active in the community, their recent contributions, 
-- and the recognition they've received in the form of badges, all while avoiding those who are less constructive as indicated by their voting behavior.
