WITH RankedPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM
        Posts p
    WHERE
        p.ViewCount > 100
),
UserBadges AS (
    SELECT
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM
        Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
),
PostVoteCounts AS (
    SELECT
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM
        Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY
        p.Id
)
SELECT
    up.DisplayName,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    pvc.UpVotes,
    pvc.DownVotes,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges
FROM
    RankedPosts rp
JOIN Users up ON rp.OwnerUserId = up.Id
LEFT JOIN UserBadges ub ON up.Id = ub.UserId
LEFT JOIN PostVoteCounts pvc ON rp.Id = pvc.PostId
WHERE
    rp.PostRank = 1
    AND rp.Score > (SELECT AVG(Score) FROM Posts WHERE Score IS NOT NULL)
ORDER BY
    ub.BadgeCount DESC,
    rp.Score DESC
LIMIT 10;
