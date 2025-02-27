
WITH UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
RecentPosts AS (
    SELECT
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.Score,
        p.CreationDate,
        @row_num := IF(@prev_owner = p.OwnerUserId, @row_num + 1, 1) AS RecentPostRank,
        @prev_owner := p.OwnerUserId
    FROM Posts p, (SELECT @row_num := 0, @prev_owner := NULL) r
    WHERE p.CreationDate >= NOW() - INTERVAL 1 YEAR
    ORDER BY p.OwnerUserId, p.CreationDate DESC
),
TopBadgedUsers AS (
    SELECT
        us.DisplayName,
        us.Reputation,
        us.BadgeCount,
        RANK() OVER (ORDER BY us.BadgeCount DESC, us.Reputation DESC) AS BadgeRank,
        us.UserId
    FROM UserStats us
    WHERE us.BadgeCount > 0
)
SELECT
    tb.DisplayName,
    tb.Reputation,
    COALESCE(rp.Title, 'No Posts Found') AS RecentPostTitle,
    COALESCE(rp.Score, 0) AS RecentPostScore,
    ts.TotalBounties,
    tb.BadgeCount AS UserBadgeCount,
    tb.BadgeRank
FROM TopBadgedUsers tb
LEFT JOIN RecentPosts rp ON tb.UserId = rp.OwnerUserId AND rp.RecentPostRank = 1
LEFT JOIN UserStats ts ON tb.UserId = ts.UserId
WHERE tb.BadgeCount = (
    SELECT MAX(BadgeCount) FROM TopBadgedUsers
)
ORDER BY tb.Reputation DESC
LIMIT 10;
