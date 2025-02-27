WITH TagStats AS (
    SELECT
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(u.Reputation) AS AvgReputation
    FROM
        Tags t
    LEFT JOIN
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    GROUP BY
        t.TagName
),

PostChangeHistory AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        ph.CreationDate AS ChangeDate,
        ph.UserDisplayName,
        p.CreationDate AS PostDate,
        ph.Comment
    FROM
        Posts p
    JOIN
        PostHistory ph ON ph.PostId = p.Id
    WHERE
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edits to Title and Body
)

SELECT
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.AvgReputation,
    pch.PostId,
    pch.Title,
    pch.ChangeDate,
    pch.UserDisplayName,
    pch.PostDate,
    pch.Comment
FROM
    TagStats ts
LEFT JOIN
    PostChangeHistory pch ON pch.PostId IN (
        SELECT PostId
        FROM Posts
        WHERE Tags LIKE '%' || ts.TagName || '%'
    )
ORDER BY
    ts.PostCount DESC,
    ts.TagName ASC,
    pch.ChangeDate DESC;
