
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
        @rownum := @rownum + 1 AS Ranking
    FROM 
        UserPostCounts, (SELECT @rownum := 0) r
    ORDER BY 
        PostCount DESC
)
SELECT 
    u.DisplayName,
    t.PostCount,
    t.QuestionCount,
    t.AnswerCount
FROM 
    TopUsers t
JOIN 
    Users u ON t.UserId = u.Id
WHERE 
    t.Ranking <= 10
ORDER BY 
    t.Ranking;
