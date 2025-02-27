-- Performance benchmarking query to analyze post statistics and user interactions

WITH PostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        COUNT(c.Id) AS TotalComments,
        COUNT(v.Id) AS TotalVotes,
        MAX(b.Date) AS LastBadgeDate
    FROM
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    WHERE
        p.CreationDate >= '2020-01-01' -- Filtering posts from the last three years
    GROUP BY
        p.Id
),

UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
)

SELECT
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.AnswerCount,
    ps.CommentCount,
    ps.FavoriteCount,
    ps.TotalComments,
    ps.TotalVotes,
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    ps.LastBadgeDate
FROM
    PostStats ps
JOIN UserStats us ON ps.OwnerUserId = us.UserId
ORDER BY
    ps.ViewCount DESC, ps.Score DESC;
