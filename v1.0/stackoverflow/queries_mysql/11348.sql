
WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        PostCount,
        QuestionCount,
        AnswerCount,
        @rankByPosts := IF(@prevPostCount = PostCount, @rank := @rank, @rank + 1) AS RankByPosts,
        @prevPostCount := PostCount,
        @rankByQuestions := IF(@prevQuestionCount = QuestionCount, @rankQ := @rankQ, @rankQ + 1) AS RankByQuestions,
        @prevQuestionCount := QuestionCount,
        @rankByAnswers := IF(@prevAnswerCount = AnswerCount, @rankA := @rankA, @rankA + 1) AS RankByAnswers
    FROM 
        UserPostCounts,
        (SELECT @rank := 0, @prevPostCount := NULL, @rankQ := 0, @prevQuestionCount := NULL, @rankA := 0, @prevAnswerCount := NULL) AS vars
    ORDER BY 
        PostCount DESC,
        QuestionCount DESC,
        AnswerCount DESC
)

SELECT 
    u.DisplayName,
    u.Reputation,
    t.PostCount,
    t.QuestionCount,
    t.AnswerCount,
    t.RankByPosts,
    t.RankByQuestions,
    t.RankByAnswers
FROM 
    TopUsers t
JOIN 
    Users u ON t.UserId = u.Id
WHERE 
    t.RankByPosts <= 10
ORDER BY 
    t.RankByPosts;
