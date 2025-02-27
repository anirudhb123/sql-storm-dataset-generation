WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.CreationDate,
        0 AS Level
    FROM Posts p
    WHERE p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.CreationDate,
        r.Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserScoreCTE AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3 AS Score
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
PostHistoryCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS HistoryCount
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id
),
FilteredBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Badges b
    WHERE b.Class = 1 -- Only gold badges
    GROUP BY b.UserId
)
SELECT 
    u.DisplayName AS UserName,
    p.Title AS PostTitle,
    ph.HistoryCount,
    COUNT(b.BadgeCount) AS GoldBadgeCount,
    ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS RecentPostRank,
    COALESCE(rh.Level, 0) AS LevelInHierarchy
FROM Users u
INNER JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN PostHistoryCounts ph ON p.Id = ph.PostId
LEFT JOIN FilteredBadges b ON u.Id = b.UserId
LEFT JOIN RecursivePostHierarchy rh ON p.Id = rh.PostId
WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
AND COALESCE(ph.HistoryCount, 0) > 0
AND (u.Location IS NOT NULL OR u.WebsiteUrl IS NOT NULL)
GROUP BY u.DisplayName, p.Title, ph.HistoryCount, rh.Level
ORDER BY GoldBadgeCount DESC, RecentPostRank
LIMIT 100;
