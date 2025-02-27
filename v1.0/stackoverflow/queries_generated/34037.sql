WITH RecursiveUserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        u.DisplayName,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        1 AS Level
    FROM Users u
    WHERE u.Reputation > 1000

    UNION ALL

    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        u.DisplayName,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        r.Level + 1
    FROM Users u
    INNER JOIN RecursiveUserStats r ON u.Id = r.UserId
    WHERE u.Reputation < r.Reputation
),

UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),

PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AverageViews
    FROM Posts p
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY p.OwnerUserId
)

SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(ubs.BadgeCount, 0) AS BadgeCount,
    COALESCE(ubs.GoldBadges, 0) AS GoldBadges,
    COALESCE(ubs.SilverBadges, 0) AS SilverBadges,
    COALESCE(ubs.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(ps.PostCount, 0) AS PostCount,
    COALESCE(ps.TotalScore, 0) AS TotalScore,
    COALESCE(ps.AverageViews, 0) AS AverageViews,
    CASE 
        WHEN u.Reputation >= 10000 THEN 'Elite'
        WHEN u.Reputation >= 5000 THEN 'Experienced'
        WHEN u.Reputation >= 1000 THEN 'Novice'
        ELSE 'Newbie'
    END AS UserTier
FROM Users u
LEFT JOIN UserBadges ubs ON u.Id = ubs.UserId
LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
WHERE u.CreationDate < (CURRENT_DATE - INTERVAL '1 year')
ORDER BY u.Reputation DESC;

WITH RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserDisplayName,
        pt.Name AS PostTypeName
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    JOIN Posts p ON ph.PostId = p.Id
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    WHERE ph.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
)

SELECT 
    r.PostId,
    STRING_AGG(DISTINCT CONCAT(r.UserDisplayName, ' (', pt.Name, ')'), ', ') AS UsersInvolved,
    COUNT(r.PostHistoryTypeId) AS HistoryEntryCount,
    MAX(r.CreationDate) AS LastChange
FROM RecentPostHistory r
GROUP BY r.PostId
HAVING COUNT(r.PostHistoryTypeId) > 5
ORDER BY LastChange DESC;

