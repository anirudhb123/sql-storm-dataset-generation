WITH UserBadges AS (
    SELECT u.Id AS UserId, u.DisplayName, COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PopularPosts AS (
    SELECT p.Id AS PostId, p.Title, p.CreationDate, p.Score, p.ViewCount, COUNT(c.Id) AS CommentCount, ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN unnest(string_to_array(p.Tags, '>')) AS tag ON TRUE
    JOIN Tags t ON t.TagName = tag
    WHERE p.PostTypeId = 1 -- Questions only
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
    HAVING COUNT(c.Id) > 5 AND p.Score > 10 -- More than 5 comments and score greater than 10
),
PostHistorySummary AS (
    SELECT ph.PostId, COUNT(ph.Id) AS RevisionCount, MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    GROUP BY ph.PostId
),
UserActivity AS (
    SELECT u.Id AS UserId, COUNT(DISTINCT p.Id) AS QuestionCount, SUM(p.Score) AS TotalScore
    FROM Users u
    JOIN Posts p ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 -- Questions only
    GROUP BY u.Id
)

SELECT ub.DisplayName, ub.BadgeCount, pp.Title, pp.CreationDate, pp.Score, pp.ViewCount, pp.CommentCount, pht.RevisionCount, pht.LastEditDate, ua.QuestionCount, ua.TotalScore
FROM UserBadges ub
JOIN PopularPosts pp ON pp.ViewCount > 1000 -- Filter popular posts
JOIN PostHistorySummary pht ON pp.PostId = pht.PostId
JOIN UserActivity ua ON ua.UserId = pp.OwnerUserId
ORDER BY ub.BadgeCount DESC, pp.Score DESC
LIMIT 10;
