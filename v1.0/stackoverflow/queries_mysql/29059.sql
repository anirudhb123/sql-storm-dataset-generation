
WITH PostTags AS (
    SELECT
        p.Id AS PostId,
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) AS Tag
    FROM
        Posts p
    INNER JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL
        SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL
        SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
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
        @rank := @rank + 1 AS Rank
    FROM
        TagUsage, (SELECT @rank := 0) r
    ORDER BY
        UsageCount DESC
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
    GROUP_CONCAT(DISTINCT pt.Tag ORDER BY pt.Tag SEPARATOR ', ') AS AssociatedTags
FROM
    PopularQuestions q
JOIN
    PostTags pt ON q.QuestionId = pt.PostId
GROUP BY
    q.QuestionId, q.Title, q.ViewCount, q.AnswerCount
ORDER BY
    q.ViewCount DESC;
