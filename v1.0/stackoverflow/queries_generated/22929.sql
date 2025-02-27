WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COALESCE(AVG(v.BountyAmount) FILTER (WHERE v.VoteTypeId = 8), 0) AS AverageBounty,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    LEFT JOIN
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag_id ON TRUE
    LEFT JOIN
        Tags t ON tag_id::int = t.Id
    WHERE
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY
        p.Id
),
ClosedPosts AS (
    SELECT
        ph.PostId,
        COUNT(*) AS CloseReasonCount,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM
        PostHistory ph
    JOIN
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE
        ph.PostHistoryTypeId = 10
    GROUP BY
        ph.PostId
),
UserStats AS (
    SELECT
        u.Id AS UserId,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        SUM(pv.ViewCount) AS TotalViews
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    LEFT JOIN
        Posts pv ON u.Id = pv.OwnerUserId
    GROUP BY
        u.Id
)
SELECT
    rp.PostId,
    rp.Title,
    rp.Score,
    COALESCE(cp.CloseReasonCount, 0) AS CloseReasonCount,
    cp.CloseReasons,
    us.TotalViews,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    rp.AverageBounty,
    rp.CommentCount,
    rp.Tags
FROM
    RankedPosts rp
LEFT JOIN
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN
    UserStats us ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = us.UserId)
WHERE
    rp.PostRank <= 3
ORDER BY
    rp.Score DESC,
    us.TotalViews DESC
LIMIT 100;

In this complex SQL query:
- Common Table Expressions (CTEs) are used to structure the data with `RankedPosts`, `ClosedPosts`, and `UserStats`.
- The `RankedPosts` CTE aggregates posts within the last year, collecting their comments, scores, average bounty amounts, and tags.
- The `ClosedPosts` CTE retrieves closed post details and their reasons.
- The `UserStats` CTE computes user badge counts and total views contributed by their posts.
- Final selection combines data from the three CTEs, filtering on post rank and ordering the result by score and view counts, demonstrating various SQL constructs including outer joins, correlated subqueries, and groupings, while also factoring in NULL logic and string expressions.
