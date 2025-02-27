WITH TagCounts AS (
    SELECT
        tag.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM
        Tags tag
    LEFT JOIN
        Posts p ON p.Tags ILIKE '%' || tag.TagName || '%'
    GROUP BY
        tag.TagName
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostsCount,
        COUNT(DISTINCT c.Id) AS CommentsCount,
        SUM(v.VoteTypeId = 2) AS Upvotes,
        SUM(v.VoteTypeId = 3) AS Downvotes
    FROM
        Users u
    LEFT JOIN
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON c.UserId = u.Id
    LEFT JOIN
        Votes v ON v.UserId = u.Id
    GROUP BY
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MIN(ph.CreationDate) AS FirstEditDate,
        MAX(ph.CreationDate) AS LastEditDate
    FROM
        PostHistory ph
    WHERE
        ph.PostHistoryTypeId IN (4, 5) -- Edit Title and Edit Body
    GROUP BY
        ph.PostId
)
SELECT
    tg.TagName,
    tc.PostCount,
    tc.QuestionCount,
    tc.AnswerCount,
    ua.UserId,
    ua.DisplayName,
    ua.PostsCount,
    ua.CommentsCount,
    ua.Upvotes,
    ua.Downvotes,
    phs.EditCount,
    phs.FirstEditDate,
    phs.LastEditDate
FROM
    TagCounts tc
JOIN
    UserActivity ua ON ua.PostsCount > 0
JOIN
    Posts p ON p.Tags ILIKE '%' || tc.TagName || '%'
LEFT JOIN
    PostHistoryStats phs ON phs.PostId = p.Id
WHERE
    tc.PostCount > 0
ORDER BY
    tc.PostCount DESC,
    ua.Upvotes DESC
LIMIT 100;
