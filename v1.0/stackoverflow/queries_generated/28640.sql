WITH TagStatistics AS (
    SELECT
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(Posts.ViewCount) AS TotalViews,
        AVG(Posts.Score) AS AverageScore
    FROM
        Tags
    JOIN
        Posts ON Tags.Id IN (SELECT unnest(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags) - 2), '><'))::int)
    WHERE
        Posts.OwnerUserId IS NOT NULL
    GROUP BY
        Tags.TagName
),
UserEngagement AS (
    SELECT
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(Posts.Id) AS PostCount,
        SUM(Posts.ViewCount) AS TotalViews,
        SUM(Posts.Score) AS TotalScore,
        COUNT(DISTINCT Comments.Id) AS CommentCount
    FROM
        Users
    LEFT JOIN
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN
        Comments ON Posts.Id = Comments.PostId
    WHERE
        Users.Reputation > 0
    GROUP BY
        Users.Id
),
TopTags AS (
    SELECT
        TagName,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM
        TagStatistics
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS Rank
    FROM
        UserEngagement
)
SELECT
    tt.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.TotalViews,
    ts.AverageScore,
    tu.DisplayName AS TopUser,
    tu.TotalViews AS UserViews
FROM
    TopTags tt
JOIN
    TagStatistics ts ON tt.TagName = ts.TagName
JOIN
    TopUsers tu ON tu.Rank = 1
WHERE
    tt.Rank <= 5
ORDER BY
    ts.PostCount DESC;
