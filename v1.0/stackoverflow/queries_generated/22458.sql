WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS MaxBadgeClass,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS PopularityRank
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1 -- Only questions
    GROUP BY p.Id, p.Title, p.ViewCount
),
RecentPostHistory AS (
    SELECT 
        h.PostId,
        h.UserId,
        ph.Name AS HistoryType,
        h.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY h.PostId ORDER BY h.CreationDate DESC) AS RecentHistoryRank
    FROM PostHistory h
    JOIN PostHistoryTypes ph ON h.PostHistoryTypeId = ph.Id
    WHERE h.CreationDate > NOW() - INTERVAL '1 year'
)
SELECT 
    u.DisplayName,
    u.Location,
    ub.BadgeCount,
    ub.MaxBadgeClass,
    pp.Title AS PopularPostTitle,
    pp.ViewCount,
    pp.UpVotes,
    pp.DownVotes,
    rp.HistoryType AS RecentActionType,
    rp.CreationDate AS RecentActionDate
FROM Users u
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN PopularPosts pp ON pp.PopularityRank = 1  -- Get the most popular post
LEFT JOIN RecentPostHistory rp ON u.Id = rp.UserId AND rp.RecentHistoryRank = 1  -- Most recent history
WHERE 
    ub.BadgeCount IS NULL OR ub.MaxBadgeClass = 1  -- Get users with no badges or with Gold badge 
    AND (u.Location IS NOT NULL OR (u.AboutMe IS NOT NULL AND LENGTH(u.AboutMe) > 100))  -- Location or about me must exist
    AND pp.ViewCount >= 1000  -- Only consider posts with at least 1000 views
ORDER BY u.Reputation DESC
LIMIT 10;
This query performs a complex analysis on users, their badges, popular posts, and recent actions in the `PostHistory` table. Several advanced SQL constructs such as CTEs, window functions, and aggregate functions are used to provide a comprehensive view of active users within the Stack Overflow schema while meeting various predicate conditions and showcasing unusual SQL semantics.
