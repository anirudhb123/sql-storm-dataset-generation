WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1 -- Questions only
),
UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
),
PostComments AS (
    SELECT
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM
        Comments c
    GROUP BY
        c.PostId
),
ClosedPosts AS (
    SELECT
        p.Id AS PostId,
        COUNT(ph.Id) AS CloseReasonCount,
        STRING_AGG(DISTINCT ctr.Name, ', ') AS CloseReasons
    FROM
        Posts p
    LEFT JOIN
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10 -- Post Closed
    LEFT JOIN
        CloseReasonTypes ctr ON ph.Comment::INTEGER = ctr.Id
    GROUP BY
        p.Id
)
SELECT
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CreationDate,
    ur.Reputation,
    ur.DisplayName,
    ur.BadgeCount,
    ur.GoldBadges,
    ur.SilverBadges,
    ur.BronzeBadges,
    COALESCE(pc.CommentCount, 0) AS TotalComments,
    cp.CloseReasonCount,
    cp.CloseReasons
FROM
    RankedPosts rp
JOIN
    Users ur ON rp.PostId IN (
        SELECT AcceptedAnswerId FROM Posts WHERE Id = rp.PostId
    )
LEFT JOIN
    PostComments pc ON rp.PostId = pc.PostId
LEFT JOIN
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE
    rp.Rank <= 10 -- Top 10 questions by score
ORDER BY
    rp.Score DESC,
    ur.Reputation DESC;
