WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        COALESCE(NULLIF(p.Body, ''), 'No content available') AS PostBody,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tag ON TRUE
    LEFT JOIN
        Tags t ON t.TagName = tag
    WHERE
        p.PostTypeId = 1 -- Questions only
    GROUP BY
        p.Id, p.Title, p.Score, p.Body
),

UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(b.Class = 1)::int AS GoldBadges,
        SUM(b.Class = 2)::int AS SilverBadges,
        SUM(b.Class = 3)::int AS BronzeBadges,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id, u.DisplayName, u.Reputation, u.Views
)

SELECT
    r.PostId,
    r.Title,
    r.PostBody,
    r.CommentCount,
    r.Tags,
    u.UserId,
    u.DisplayName AS AuthorName,
    u.Reputation AS AuthorReputation,
    u.Views AS AuthorViews,
    u.QuestionCount AS UserQuestionCount,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    u.TotalBadges,
    CASE
        WHEN r.PostRank = 1 THEN 'Latest'
        ELSE 'Earlier'
    END AS PostStatus
FROM
    RankedPosts r
JOIN
    UserReputation u ON r.OwnerUserId = u.UserId
ORDER BY
    r.Score DESC, r.CreationDate DESC
LIMIT 100;
