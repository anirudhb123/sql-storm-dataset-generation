
WITH UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViews
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalScore,
        AvgViews,
        @rank := @rank + 1 AS Rank
    FROM
        UserPostStats, (SELECT @rank := 0) AS r
    ORDER BY
        TotalScore DESC
)

SELECT
    *
FROM
    TopUsers
WHERE
    Rank <= 10;
