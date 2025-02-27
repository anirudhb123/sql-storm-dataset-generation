WITH PostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS Upvotes,
        SUM(v.VoteTypeId = 3) AS Downvotes,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    LEFT JOIN
        Badges b ON p.OwnerUserId = b.UserId
    WHERE
        p.CreationDate >= '2022-01-01' AND p.CreationDate < '2023-01-01'
    GROUP BY
        p.Id, p.Title
), RankedPosts AS (
    SELECT
        PostId,
        Title,
        CommentCount,
        Upvotes,
        Downvotes,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        RANK() OVER (ORDER BY Upvotes - Downvotes DESC) AS PostRank
    FROM
        PostStats
)
SELECT
    rp.PostId,
    rp.Title,
    rp.CommentCount,
    rp.Upvotes,
    rp.Downvotes,
    rp.GoldBadges,
    rp.SilverBadges,
    rp.BronzeBadges,
    rp.PostRank
FROM
    RankedPosts rp
WHERE
    rp.PostRank <= 10
ORDER BY
    rp.PostRank;
