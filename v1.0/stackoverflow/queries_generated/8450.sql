WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        MAX(b.Class) AS HighestBadgeClass,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, p.Title
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
)
SELECT 
    ps.Title,
    us.DisplayName,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    us.PostCount,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    ps.CloseCount,
    ps.ReopenCount,
    ps.HighestBadgeClass
FROM PostStats ps
JOIN UserStats us ON ps.OwnerUserId = us.UserId
ORDER BY ps.UpVotes DESC, ps.CommentCount DESC, us.PostCount DESC
LIMIT 100;
