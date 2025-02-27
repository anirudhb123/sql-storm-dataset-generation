
WITH UserPostActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        @rank := @rank + 1 AS Rank
    FROM 
        UserPostActivity, (SELECT @rank := 0) r
    ORDER BY 
        Reputation DESC
)

SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostCount,
    QuestionCount,
    AnswerCount
FROM 
    TopUsers
WHERE 
    Rank <= 10;
