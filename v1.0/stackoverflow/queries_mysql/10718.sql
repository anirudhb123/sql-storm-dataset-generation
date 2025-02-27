
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePostCount,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    UserId,
    Reputation,
    PostCount,
    QuestionCount,
    AnswerCount,
    PositivePostCount,
    AvgViewCount
FROM 
    UserPostStats
ORDER BY 
    Reputation DESC,
    PostCount DESC;
