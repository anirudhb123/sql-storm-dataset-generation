WITH RECURSIVE UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        1 AS Level
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000  -- Only consider users with high reputation

    UNION ALL

    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        us.Level + 1 AS Level
    FROM 
        Users u
    JOIN UserStats us ON u.Id != us.UserId AND u.Reputation > us.Reputation  -- Get higher reputation users
    WHERE 
        us.Level < 5  -- Limit the recursion for performance
)

, RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month' 
        AND p.OwnerUserId IS NOT NULL
)

SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.CreationDate,
    COUNT(DISTINCT rp.PostId) AS RecentPostCount,
    AVG(rp.Score) AS AveragePostScore,
    CASE 
        WHEN COUNT(bp.Id) > 0 THEN 'Has Badges' 
        ELSE 'No Badges' 
    END AS BadgeStatus
FROM 
    UserStats us
LEFT JOIN 
    RecentPosts rp ON us.UserId = rp.OwnerUserId
LEFT JOIN 
    Badges bp ON us.UserId = bp.UserId
WHERE 
    us.Reputation > 1000 
GROUP BY 
    us.UserId, us.DisplayName, us.Reputation, us.CreationDate
HAVING 
    COUNT(DISTINCT rp.PostId) > 0  -- Only include users with recent posts
ORDER BY 
    us.Reputation DESC, RecentPostCount DESC;

-- Find common tags across the recent posts for users with significant contributions
WITH TagCounts AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 10  -- Consider tags used in more than 10 posts
)

SELECT 
    uc.UserId,
    uc.DisplayName,
    tc.TagName,
    tc.PostCount
FROM 
    UserStats uc
JOIN 
    RecentPosts rp ON uc.UserId = rp.OwnerUserId
JOIN 
    TagCounts tc ON rp.Tags LIKE CONCAT('%', tc.TagName, '%')
ORDER BY 
    uc.Reputation DESC, tc.PostCount DESC;
