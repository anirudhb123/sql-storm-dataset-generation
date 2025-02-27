WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM
        Posts p
    LEFT JOIN
        Comments c ON c.PostId = p.Id
    WHERE
        p.PostTypeId IN (1, 2) -- Considering only Questions and Answers
    GROUP BY
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.OwnerUserId
),
UserBadges AS (
    SELECT
        u.Id AS UserId,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
),
PostHistoryDetails AS (
    SELECT
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        UPPER(ph.Comment) AS Comment,
        CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END AS IsClosed
    FROM
        PostHistory ph
    WHERE
        ph.CreationDate > NOW() - INTERVAL '1 year'
)
SELECT
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    rp.CommentCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    MAX(CASE WHEN p.IsClosed = 1 THEN p.CreationDate END) AS LastClosedDate,
    COUNT(DISTINCT (CASE WHEN p.PostHistoryTypeId IN (10, 11) THEN p.PostHistoryTypeId END)) AS CloseHistoryCount,
    STRING_AGG(DISTINCT ph.Comment, '; ') AS RelevantComments
FROM
    RankedPosts rp
LEFT JOIN
    UserBadges ub ON ub.UserId = rp.OwnerUserId
LEFT JOIN
    PostHistoryDetails p ON p.PostId = rp.PostId
GROUP BY
    rp.PostId, rp.Title, rp.Score, rp.ViewCount, rp.CreationDate, rp.CommentCount, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges
HAVING
    SUM(CASE WHEN rp.ViewCount > 500 THEN 1 ELSE 0 END) > 0
    AND AVG(rp.Score) > 0
ORDER BY
    rp.ViewCount DESC,
    rp.Score DESC
LIMIT 50;
