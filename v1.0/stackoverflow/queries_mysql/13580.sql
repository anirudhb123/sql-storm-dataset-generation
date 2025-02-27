
WITH UserPostCount AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
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
        @rank := IF(@prevPostCount = PostCount, @rank, @rank + 1) AS RankByPosts,
        @prevPostCount := PostCount
    FROM 
        UserPostCount, (SELECT @rank := 0, @prevPostCount := NULL) r
    ORDER BY 
        PostCount DESC
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    RankByPosts
FROM 
    TopUsers
WHERE 
    RankByPosts <= 10;
