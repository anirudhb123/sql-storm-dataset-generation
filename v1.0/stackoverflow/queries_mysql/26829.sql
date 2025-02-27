
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
TagStats AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostsWithTag,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.AnswerCount) AS TotalAnswers
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    GROUP BY t.Id, t.TagName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        Questions,
        Answers,
        TotalViews,
        TotalScore,
        @userRank := @userRank + 1 AS Rank
    FROM UserPostStats, (SELECT @userRank := 0) AS r
    WHERE TotalPosts > 0
    ORDER BY TotalScore DESC
),
TopTags AS (
    SELECT 
        TagId,
        TagName,
        PostsWithTag,
        TotalViews,
        TotalAnswers,
        @tagRank := @tagRank + 1 AS Rank
    FROM TagStats, (SELECT @tagRank := 0) AS r
    WHERE PostsWithTag > 0
    ORDER BY TotalViews DESC
)
SELECT 
    tu.Rank AS UserRank,
    tu.DisplayName AS TopUser,
    tu.TotalPosts,
    tu.Questions,
    tu.Answers,
    tu.TotalViews AS UserTotalViews,
    tu.TotalScore AS UserTotalScore,
    tt.Rank AS TagRank,
    tt.TagName AS TopTag,
    tt.PostsWithTag,
    tt.TotalViews AS TagTotalViews,
    tt.TotalAnswers AS TagTotalAnswers
FROM TopUsers tu
JOIN TopTags tt ON tu.TotalViews > 1000 AND tt.TotalViews > 1000
WHERE tu.Rank <= 10 AND tt.Rank <= 10
ORDER BY tu.Rank, tt.Rank;
