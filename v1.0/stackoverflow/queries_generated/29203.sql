WITH PostTagCount AS (
    SELECT
        p.Id AS PostId,
        COUNT(t.TagName) AS TagCount,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM
        Posts p
    LEFT JOIN
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '> <')::int[])
    GROUP BY
        p.Id
),
UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COALESCE(SUM(ph.CreationDate IS NOT NULL), 0) AS HistoryCount
    FROM
        Users u
    LEFT JOIN
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN
        PostHistory ph ON ph.UserId = u.Id
    GROUP BY
        u.Id
),
PostDetails AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        pt.Name AS PostType,
        up.UserId,
        up.DisplayName,
        pt.Name AS PostTypeName,
        pc.TagCount,
        pc.Tags,
        up.QuestionCount,
        up.AnswerCount,
        up.PostCount,
        up.HistoryCount
    FROM
        Posts p
    JOIN
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN
        UserPostStats up ON p.OwnerUserId = up.UserId
    JOIN
        PostTagCount pc ON p.Id = pc.PostId
    WHERE
        (p.CreationDate >= CURRENT_DATE - INTERVAL '30 days') AND
        (p.ViewCount > 100) AND
        (p.Body IS NOT NULL AND LENGTH(p.Body) > 500)
)
SELECT
    pd.PostId,
    pd.Title,
    pd.PostType,
    pd.Body,
    pd.Tags,
    pd.TagCount,
    pd.QuestionCount,
    pd.AnswerCount,
    pd.PostCount,
    pd.HistoryCount,
    CASE 
        WHEN pd.ViewCount > 1000 THEN 'High Visibility'
        WHEN pd.ViewCount BETWEEN 500 AND 1000 THEN 'Moderate Visibility'
        ELSE 'Low Visibility' 
    END AS VisibilityCategory
FROM
    PostDetails pd
ORDER BY
    pd.TagCount DESC, pd.ViewCount DESC;
