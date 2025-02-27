WITH TagStatistics AS (
    SELECT
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS WikiCount,
        AVG(COALESCE(p.Score, 0)) AS AverageScore
    FROM Tags t
    LEFT JOIN Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY t.TagName
),
UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsMade,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersProvided,
        SUM(CASE WHEN p.PostTypeId = 1 THEN COALESCE(p.Score, 0) ELSE 0 END) AS TotalQuestionScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
),
TopTags AS (
    SELECT
        ts.TagName,
        ts.PostCount,
        ts.QuestionCount,
        ts.AnswerCount,
        ts.WikiCount,
        ts.AverageScore,
        RANK() OVER (ORDER BY ts.PostCount DESC) AS Rank
    FROM TagStatistics ts
    WHERE ts.PostCount > 0
),
ActiveUsers AS (
    SELECT
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ur.PostsMade,
        ur.QuestionsAsked,
        ur.AnswersProvided,
        ur.TotalQuestionScore,
        RANK() OVER (ORDER BY ur.Reputation DESC) AS ReputationRank
    FROM UserReputation ur
    WHERE ur.PostsMade > 0
)
SELECT
    tu.TagName,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.WikiCount,
    tu.AverageScore,
    au.DisplayName AS TopUser,
    au.Reputation AS UserReputation,
    au.QuestionsAsked,
    au.AnswersProvided
FROM TopTags tu
JOIN ActiveUsers au ON tu.QuestionCount > 0
WHERE tu.Rank <= 10 AND au.ReputationRank <= 10
ORDER BY tu.PostCount DESC, au.Reputation DESC;
