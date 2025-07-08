
WITH PostTags AS (
    SELECT
        p.Id AS PostId,
        TRIM(value) AS Tag
    FROM
        Posts p,
        TABLE(FLATTEN(input => SPLIT(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><'))) AS value
    WHERE
        p.PostTypeId = 1 
),
TagUsage AS (
    SELECT
        Tag,
        COUNT(*) AS UsageCount
    FROM
        PostTags
    GROUP BY
        Tag
),
TopTags AS (
    SELECT
        Tag,
        UsageCount,
        ROW_NUMBER() OVER (ORDER BY UsageCount DESC) AS Rank
    FROM
        TagUsage
),
PopularQuestions AS (
    SELECT
        p.Id AS QuestionId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        t.UsageCount
    FROM
        Posts p
    JOIN
        PostTags pt ON p.Id = pt.PostId
    JOIN
        TopTags t ON pt.Tag = t.Tag
    WHERE
        p.PostTypeId = 1 
        AND t.Rank <= 10 
)
SELECT
    q.QuestionId,
    q.Title,
    q.ViewCount,
    q.AnswerCount,
    LISTAGG(DISTINCT pt.Tag, ', ') WITHIN GROUP (ORDER BY pt.Tag) AS AssociatedTags
FROM
    PopularQuestions q
JOIN
    PostTags pt ON q.QuestionId = pt.PostId
GROUP BY
    q.QuestionId, q.Title, q.ViewCount, q.AnswerCount
ORDER BY
    q.ViewCount DESC;
