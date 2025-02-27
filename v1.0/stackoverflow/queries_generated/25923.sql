WITH TagCounts AS (
    SELECT
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews
    FROM
        Tags t
    LEFT JOIN
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY
        t.TagName
),

UserEngagement AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS TotalUpvotes,
        SUM(v.VoteTypeId = 3) AS TotalDownvotes,
        SUM(p.ViewCount) AS TotalViews
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    GROUP BY
        u.Id
)

SELECT
    tc.TagName,
    tc.PostCount,
    tc.QuestionCount,
    tc.AnswerCount,
    tc.TotalViews,
    ue.DisplayName,
    ue.QuestionCount AS UserQuestions,
    ue.AnswerCount AS UserAnswers,
    ue.TotalUpvotes,
    ue.TotalDownvotes,
    ue.TotalViews AS UserTotalViews,
    ROW_NUMBER() OVER (PARTITION BY tc.TagName ORDER BY ue.TotalUpvotes DESC) AS UserRank
FROM
    TagCounts tc
JOIN
    UserEngagement ue ON ue.UserQuestions > 0 OR ue.UserAnswers > 0
WHERE
    tc.PostCount > 0
ORDER BY
    tc.TotalViews DESC, tc.PostCount DESC, ue.TotalUpvotes DESC
LIMIT 100;
