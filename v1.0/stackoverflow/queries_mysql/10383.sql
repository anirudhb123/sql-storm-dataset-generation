
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS WikiCount
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
        WikiCount,
        @rank := @rank + 1 AS Rank
    FROM 
        UserPostStats, (SELECT @rank := 0) r
    ORDER BY 
        PostCount DESC
)
SELECT 
    Rank,
    UserId,
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    WikiCount
FROM 
    TopUsers
WHERE 
    Rank <= 10;
