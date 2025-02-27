WITH UserReputation AS (
    SELECT Id, Reputation, COUNT(Badges.Id) AS BadgeCount
    FROM Users
    LEFT JOIN Badges ON Users.Id = Badges.UserId
    GROUP BY Users.Id, Users.Reputation
),
PostStats AS (
    SELECT 
        Posts.OwnerUserId,
        COUNT(Posts.Id) AS PostCount,
        SUM(Posts.ViewCount) AS TotalViews,
        AVG(Posts.Score) AS AvgScore,
        MAX(Posts.CreationDate) AS LastPostDate
    FROM Posts
    GROUP BY Posts.OwnerUserId
),
RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
)
SELECT 
    ur.Id AS UserId,
    ur.Reputation,
    ur.BadgeCount,
    ps.PostCount,
    ps.TotalViews,
    ps.AvgScore,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate
FROM UserReputation ur
LEFT JOIN PostStats ps ON ur.Id = ps.OwnerUserId
LEFT JOIN RecentPosts rp ON ur.Id = rp.OwnerUserId AND rp.rn = 1
WHERE ur.Reputation > 1000
ORDER BY ur.Reputation DESC, ps.TotalViews DESC
LIMIT 10;

SELECT DISTINCT 
    u.Id,
    u.DisplayName,
    CASE 
        WHEN u.Location IS NOT NULL THEN u.Location 
        ELSE 'Location Unknown' 
    END AS DisplayLocation,
    COALESCE(p.Title, 'No Posts') AS LatestPostTitle
FROM Users u
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
WHERE u.CreationDate < CURRENT_DATE - INTERVAL '1 year'
AND (u.AboutMe LIKE '%developer%' OR u.AboutMe LIKE '%engineer%')
ORDER BY u.Reputation DESC
OFFSET 5
FETCH NEXT 5 ROWS ONLY;
