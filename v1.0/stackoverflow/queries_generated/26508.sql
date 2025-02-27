WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),

PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS Upvotes,
        SUM(v.VoteTypeId = 3) AS Downvotes,
        COUNT(DISTINCT CASE WHEN b.Id IS NOT NULL THEN b.Id END) AS BadgeCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagNames
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN UserBadges ub ON p.OwnerUserId = ub.UserId
    LEFT JOIN Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE p.PostTypeId = 1 -- We are only interested in Questions
    GROUP BY p.Id, p.Title, p.PostTypeId
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CommentCount,
    ps.Upvotes,
    ps.Downvotes,
    ps.BadgeCount AS UserBadgeCount,
    ub.BadgeNames AS UserBadges,
    ps.TagNames
FROM PostStats ps
JOIN UserBadges ub ON ps.OwnerUserId = ub.UserId
WHERE ub.BadgeCount > 0
ORDER BY ps.CommentCount DESC, ps.Upvotes DESC
LIMIT 10;
