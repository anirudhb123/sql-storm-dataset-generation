
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        COALESCE(NULLIF(p.Body, ''), 'No content available') AS PostBody,
        COUNT(c.Id) AS CommentCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
        @row_number := IF(@current_user = p.OwnerUserId, @row_number + 1, 1) AS PostRank,
        @current_user := p.OwnerUserId,
        p.OwnerUserId,
        p.CreationDate
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    JOIN
        (SELECT @row_number := 0, @current_user := NULL) AS vars
    LEFT JOIN
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS tag
         FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag ON TRUE
    LEFT JOIN
        Tags t ON t.TagName = tag
    WHERE
        p.PostTypeId = 1 
    GROUP BY
        p.Id, p.Title, p.Score, p.Body, p.OwnerUserId, p.CreationDate
),

UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
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
