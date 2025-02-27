WITH RankedPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM
        Posts p
    WHERE
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId = 1 -- Only questions
),
UserStatistics AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT coalesce(c.UserId, -1)) AS TotalComments
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Comments c ON c.PostId = p.Id
    GROUP BY
        u.Id
)
SELECT
    us.DisplayName,
    us.TotalPosts,
    us.TotalComments,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    json_agg(json_build_object('PostId', rp.Id, 'Title', rp.Title, 'Score', rp.Score)) AS RecentPosts
FROM
    UserStatistics us
LEFT JOIN
    RankedPosts rp ON us.UserId = rp.Id
WHERE
    us.TotalPosts > 5
GROUP BY
    us.UserId
HAVING
    SUM(rp.Score) > 0
ORDER BY
    us.TotalPosts DESC, us.TotalComments DESC;
