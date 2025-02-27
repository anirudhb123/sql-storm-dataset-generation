WITH TagStats AS (
    SELECT
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(
            CASE
                WHEN p.PostTypeId = 1 THEN 1
                ELSE 0
            END
        ) AS QuestionCount,
        SUM(
            CASE
                WHEN p.PostTypeId = 2 THEN 1
                ELSE 0
            END
        ) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount,
        ARRAY_AGG(DISTINCT u.DisplayName) AS TopContributors
    FROM
        Tags t
    JOIN
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        t.Count > 10 -- Tags with more than 10 associated posts
    GROUP BY
        t.TagName
),
TopTags AS (
    SELECT
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalScore,
        AvgViewCount,
        TopContributors,
        RANK() OVER (ORDER BY TotalScore DESC) AS RankByScore
    FROM
        TagStats
)
SELECT
    TagName,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalScore,
    AvgViewCount,
    TopContributors
FROM
    TopTags
WHERE
    RankByScore <= 10 -- Top 10 tags by score
ORDER BY
    TotalScore DESC;
