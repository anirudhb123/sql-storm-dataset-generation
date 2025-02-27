
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(TIMESTAMPDIFF(SECOND, p.CreationDate, COALESCE(p.LastActivityDate, '2024-10-01 12:34:56'))) AS AvgPostAgeSeconds
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
        TotalScore,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserActivity
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.PostCount,
    tu.TotalScore,
    tu.QuestionCount,
    tu.AnswerCount,
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    (SELECT COUNT(DISTINCT u.Id) FROM Users u JOIN Posts p ON u.Id = p.OwnerUserId) AS TotalUsers,
    (SELECT COUNT(DISTINCT p.Id) FROM Posts p WHERE p.PostTypeId = 1) AS TotalQuestions,
    (SELECT COUNT(DISTINCT p.Id) FROM Posts p WHERE p.PostTypeId = 2) AS TotalAnswers,
    (SELECT AVG(p.Score) FROM Posts p) AS AvgPostScore
FROM 
    TopUsers tu
WHERE 
    tu.ScoreRank <= 10
ORDER BY 
    tu.TotalScore DESC;
