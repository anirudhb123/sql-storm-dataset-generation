WITH UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COUNT(DISTINCT bh.Id) AS BadgeCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT p2.Id) AS RelatedPostsCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges bh ON u.Id = bh.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN PostLinks pl ON p.Id = pl.PostId
    LEFT JOIN Posts p2 ON pl.RelatedPostId = p2.Id
    GROUP BY u.Id, u.DisplayName
),
QuestionTags AS (
    SELECT
        p.Id AS QuestionId,
        STRING_AGG(DISTINCT TRIM(UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><'))), ', ') AS TagsList
    FROM Posts p
    WHERE p.PostTypeId = 1
    GROUP BY p.Id
),
TopQuestions AS (
    SELECT
        p.Id AS QuestionId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        qt.TagsList
    FROM Posts p
    JOIN QuestionTags qt ON p.Id = qt.QuestionId
    WHERE p.PostTypeId = 1
    ORDER BY p.Score DESC, p.ViewCount DESC
    LIMIT 10
)
SELECT
    us.DisplayName,
    us.QuestionCount,
    us.AnswerCount,
    us.BadgeCount,
    us.VoteCount,
    us.CommentCount,
    tq.QuestionId,
    tq.Title,
    tq.Score,
    tq.ViewCount,
    tq.CreationDate,
    tq.TagsList
FROM UserStats us
LEFT JOIN TopQuestions tq ON us.QuestionCount > 5
ORDER BY us.Reputation DESC, us.DisplayName
LIMIT 20;
