WITH RecursiveCTE AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        0 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Starting with Questions
    UNION ALL
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        Level + 1
    FROM Posts p
    INNER JOIN RecursiveCTE r ON p.ParentId = r.PostId
),
PostStats AS (
    SELECT
        p.Id,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        COALESCE(SUM(v.VoteTypeId = 10), 0) AS Deletes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id
),
UserBadges AS (
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
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    r.Level AS AnswerLevel,
    CASE 
        WHEN ps.Deletes > 0 THEN 'Deleted'
        WHEN ps.DownVotes > ps.UpVotes THEN 'Negative'
        ELSE 'Positive'
    END AS PostMood
FROM Posts p
JOIN PostStats ps ON p.Id = ps.Id
JOIN UserBadges ub ON p.OwnerUserId = ub.UserId
LEFT JOIN RecursiveCTE r ON p.Id = r.PostId
WHERE ps.CommentCount > 5
ORDER BY ps.UpVotes DESC, p.CreationDate DESC
LIMIT 100;
