WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY t.TagName ORDER BY p.Score DESC) AS rn
    FROM
        Posts p
    JOIN
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[])
    WHERE
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TopPosts AS (
    SELECT
        rp.*,
        t.TagName
    FROM
        RankedPosts rp
    INNER JOIN
        Tags t ON t.TagName IN (SELECT unnest(string_to_array(rp.Tags, '><')))
    WHERE
        rp.rn <= 5 -- Top 5 per tag
),
UserEngagement AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM
        Users u
    LEFT JOIN
        Comments c ON c.UserId = u.Id
    LEFT JOIN
        Votes v ON v.UserId = u.Id
    LEFT JOIN
        Badges b ON b.UserId = u.Id
    GROUP BY
        u.Id, u.DisplayName
)
SELECT
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.ViewCount,
    tp.Score,
    tp.AnswerCount,
    tp.CommentCount,
    STRING_AGG(DISTINCT tp.TagName, ', ') AS Tags,
    ue.DisplayName AS TopCommenter,
    ue.CommentCount AS TopCommenterCount,
    ue.VoteCount AS TopCommenterVoteCount,
    ue.GoldBadges AS TopCommenterGoldBadges,
    ue.SilverBadges AS TopCommenterSilverBadges,
    ue.BronzeBadges AS TopCommenterBronzeBadges
FROM
    TopPosts tp
LEFT JOIN
    UserEngagement ue ON ue.UserId = (SELECT c.UserId FROM Comments c WHERE c.PostId = tp.PostId ORDER BY c.CreationDate DESC LIMIT 1)
GROUP BY
    tp.PostId, ue.DisplayName
ORDER BY
    tp.Score DESC,
    tp.ViewCount DESC;
