WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        MAX(p.CreationDate) AS LastPostDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalScore,
        TotalViews,
        LastPostDate,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM UserPostStats
),
TagUsage AS (
    SELECT 
        p.OwnerUserId,
        t.TagName,
        COUNT(t.Id) AS TagCount,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(t.Id) DESC) AS TagRank
    FROM Posts p
    JOIN UNNEST(string_to_array(p.Tags, '> <')) AS t(tag) ON TRUE
    JOIN Tags t ON t.TagName = TRIM(both '<>' FROM t.tag)
    GROUP BY p.OwnerUserId, t.TagName
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.TotalScore,
    tu.TotalViews,
    tu.LastPostDate,
    STRING_AGG(CONCAT(hu.TagName, ': ', hu.TagCount) ORDER BY hu.TagCount DESC) AS TopTags
FROM TopUsers tu
LEFT JOIN TagUsage hu ON tu.UserId = hu.OwnerUserId AND hu.TagRank <= 3
WHERE tu.ScoreRank <= 10
GROUP BY tu.UserId, tu.DisplayName, tu.PostCount, tu.QuestionCount, tu.AnswerCount, tu.TotalScore, tu.TotalViews, tu.LastPostDate
ORDER BY tu.TotalScore DESC;
