WITH RankedPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    WHERE
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY
        p.Id
),

UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(b.Class = 1)::int, 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2)::int, 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3)::int, 0) AS BronzeBadges
    FROM
        Users u
    LEFT JOIN
        Votes v ON u.Id = v.UserId
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
),

PostSummary AS (
    SELECT
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        us.DisplayName,
        us.Reputation,
        us.UpVotes,
        us.DownVotes,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges
    FROM
        RankedPosts rp
    JOIN
        Users u ON rp.OwnerUserId = u.Id
    JOIN
        UserStats us ON u.Id = us.UserId
    WHERE
        rp.PostRank = 1
)

SELECT
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.DisplayName,
    CASE
        WHEN ps.Reputation > 1000 THEN 'High Reputation User'
        WHEN ps.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation User'
        ELSE 'Low Reputation User'
    END AS ReputationCategory,
    (ps.UpVotes - ps.DownVotes) AS NetVotes,
    CONCAT('Gold: ', ps.GoldBadges, ', Silver: ', ps.SilverBadges, ', Bronze: ', ps.BronzeBadges) AS BadgeSummary
FROM
    PostSummary ps
WHERE
    ps.ViewCount > (
        SELECT AVG(ViewCount) FROM Posts
    )
ORDER BY
    ps.ViewCount DESC
LIMIT 10;

