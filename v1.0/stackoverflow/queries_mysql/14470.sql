
WITH UserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore
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
        @rank := @rank + 1 AS Rank
    FROM 
        UserPosts, (SELECT @rank := 0) r
    ORDER BY 
        TotalScore DESC
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalScore
FROM 
    TopUsers
WHERE 
    Rank <= 10;
