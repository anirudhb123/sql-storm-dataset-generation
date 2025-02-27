
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        Reputation,
        PostCount, 
        QuestionCount, 
        AnswerCount,
        @row_number := @row_number + 1 AS Rank
    FROM 
        UserStats, (SELECT @row_number := 0) AS rn
    ORDER BY 
        Reputation DESC
)
SELECT 
    UserId, 
    Reputation,
    PostCount, 
    QuestionCount, 
    AnswerCount
FROM 
    TopUsers
WHERE 
    Rank <= 10;
