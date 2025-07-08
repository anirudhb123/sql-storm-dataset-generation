
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(DATEDIFF(EPOCH, p.CreationDate, COALESCE(p.LastActivityDate, '2024-10-01 12:34:56'::TIMESTAMP))) AS AvgPostAgeSeconds
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
        AvgPostAgeSeconds,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserActivity
),
StackOverflowStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT u.Id) AS TotalUsers,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        AVG(p.Score) AS AvgPostScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.PostCount,
    tu.TotalScore,
    tu.QuestionCount,
    tu.AnswerCount,
    s.TotalPosts,
    s.TotalUsers,
    s.TotalQuestions,
    s.TotalAnswers,
    s.AvgPostScore
FROM 
    TopUsers tu,
    StackOverflowStats s
WHERE 
    tu.ScoreRank <= 10
ORDER BY 
    tu.TotalScore DESC;
