WITH RecursivePostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Only questions

    UNION ALL

    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        r.Level + 1
    FROM Posts p
    INNER JOIN Posts ans ON p.Id = ans.ParentId
    INNER JOIN RecursivePostStats r ON r.PostId = ans.Id
),

PostVoteStats AS (
    SELECT
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM Votes v
    GROUP BY v.PostId
),

UserBadgeStats AS (
    SELECT
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)

SELECT
    p.Title,
    p.CreationDate,
    COALESCE(up.UpVotes, 0) AS UpVoteCount,
    COALESCE(up.DownVotes, 0) AS DownVoteCount,
    ps.RevisionCount,
    u.UserId,
    u.DisplayName,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges
FROM Posts p
LEFT JOIN (
    SELECT PostId, SUM(Level) AS RevisionCount
    FROM RecursivePostStats
    GROUP BY PostId
) ps ON p.Id = ps.PostId
LEFT JOIN PostVoteStats up ON p.Id = up.PostId
LEFT JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN UserBadgeStats ub ON u.Id = ub.UserId
WHERE p.CreationDate >= NOW() - INTERVAL '1 year' -- Only recent posts
ORDER BY p.Score DESC, p.ViewCount DESC
LIMIT 100;
