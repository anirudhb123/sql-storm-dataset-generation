
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS WikiCount
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
        WikiCount,
        @row_num := @row_num + 1 AS Rank
    FROM 
        UserReputation, (SELECT @row_num := 0) AS init
    WHERE 
        PostCount > 0
    ORDER BY 
        Reputation DESC
)
SELECT 
    tu.UserId,
    tu.Reputation,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.WikiCount,
    b.Name AS BadgeName,
    b.Class AS BadgeClass
FROM 
    TopUsers tu
LEFT JOIN 
    Badges b ON tu.UserId = b.UserId AND b.Class = 1
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.Reputation DESC;
