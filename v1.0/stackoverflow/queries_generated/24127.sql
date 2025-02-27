WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.OwnerUserId,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,  -- Assuming 2 is for Upvote
        SUM(v.VoteTypeId = 3) AS DownVoteCount -- Assuming 3 is for Downvote
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.CreationDate >= (CURRENT_DATE - INTERVAL '1 year')
    GROUP BY
        p.Id, p.OwnerUserId, p.Score
),
UserBadges AS (
    SELECT
        u.Id AS UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
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
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS EditTypes
    FROM
        PostHistory ph
    JOIN
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY
        ph.PostId
)

SELECT
    u.Id AS UserId,
    u.DisplayName,
    rp.PostId,
    rp.Score,
    rp.CommentCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    COALESCE(phd.LastEditDate, 'Never') AS LastEditDate,
    CASE
        WHEN rp.ScoreRank = 1 AND ub.GoldBadges > 0 THEN 'Top Contributor with Gold Badge'
        WHEN rp.ScoreRank = 1 THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorStatus,
    CASE
        WHEN rp.UpVoteCount > rp.DownVoteCount THEN 'More Popular'
        WHEN rp.UpVoteCount < rp.DownVoteCount THEN 'Less Popular'
        ELSE 'Equally Rated'
    END AS PopularityStatus,
    (SELECT COUNT(*)
     FROM Posts p2
     WHERE p2.OwnerUserId = u.Id
     AND p2.ViewCount > (SELECT AVG(ViewCount) FROM Posts)) AS AboveAverageViewsPosts
FROM
    Users u
JOIN
    RankedPosts rp ON u.Id = rp.OwnerUserId
LEFT JOIN
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN
    PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE
    (ub.GoldBadges > 0 OR ub.SilverBadges > 0)
    AND EXISTS (
        SELECT 1 FROM Posts p
        WHERE p.OwnerUserId = u.Id
        AND p.ViewCount IS NOT NULL
        HAVING AVG(p.ViewCount) > 100
    )
ORDER BY
    rp.Score DESC,
    u.Reputation DESC;
