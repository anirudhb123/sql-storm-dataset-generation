
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        GROUP_CONCAT(b.Name SEPARATOR ', ') AS Badges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerDisplayName,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') AS Tags
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            p.Id AS PostId, 
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', nums.n), '><', -1) AS TagName
        FROM Posts p
        JOIN (
            SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL
            SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL
            SELECT 10
        ) nums ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= nums.n - 1
    ) AS t ON t.PostId = p.Id
    WHERE p.PostTypeId = 1 
    GROUP BY p.Id, p.Title, p.OwnerDisplayName, p.Score, p.ViewCount
    ORDER BY p.Score DESC, p.ViewCount DESC
    LIMIT 10
),
UserActivity AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(v.Id) AS VoteCount,
        MAX(uh.CreationDate) AS LastVoteDate
    FROM Posts p
    JOIN Votes v ON p.Id = v.PostId
    JOIN Users uh ON v.UserId = uh.Id
    WHERE uh.Reputation > 1000 
    GROUP BY p.Id, p.OwnerUserId
)
SELECT 
    ub.UserId,
    ub.DisplayName,
    ub.BadgeCount,
    ub.Badges,
    pp.PostId,
    pp.Title,
    pp.OwnerDisplayName,
    pp.Score,
    pp.ViewCount,
    pp.CommentCount,
    pp.Tags,
    ua.VoteCount,
    ua.LastVoteDate
FROM UserBadges ub
JOIN PopularPosts pp ON pp.OwnerDisplayName = ub.DisplayName
LEFT JOIN UserActivity ua ON pp.PostId = ua.PostId
ORDER BY ub.BadgeCount DESC, pp.Score DESC, pp.ViewCount DESC;
